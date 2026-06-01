# ==============================================================================
# locals: 共通タグおよびモジュール全体で使用する派生値を定義する。
# ==============================================================================

locals {
  # 全リソースに付与する共通タグ。呼び出し側から渡された追加タグをマージする。
  common_tags = var.tags

  # AMIの解決優先度: 変数指定 > SSMパラメータストアから自動取得。
  ami_id = coalesce(var.ami_id, data.aws_ssm_parameter.al2023_ami.value)

  # ASGの希望台数: 未指定の場合は最小台数と同じ値を使用する。
  asg_desired_capacity = coalesce(var.asg_desired_capacity, var.asg_min_size)

  # IAMインスタンスプロファイル: 外部指定があればそちらを優先し、なければモジュール内で作成したものを使用する。
  instance_profile_arn = coalesce(
    var.iam_instance_profile_arn,
    aws_iam_instance_profile.this[0].arn,
  )

  # モジュール内でIAMリソースを作成するか否かを示すフラグ。
  create_iam = var.iam_instance_profile_arn == null

  # リソース名のプレフィックス。命名の一貫性を保つために全リソースで使用する。
  name_prefix = "${var.project}-${var.env}"
}

# ==============================================================================
# データソース: AMIをSSMパラメータストアから動的に取得する。
# 変数でAMI IDが指定されている場合も呼び出しは行うが、locals内で無視する。
# ==============================================================================

# Amazon Linux 2023の最新AMIをSSMパラメータストア経由で取得する。
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ==============================================================================
# セキュリティグループ: ALBからのインバウンドのみを許可し、最小権限を徹底する。
# ==============================================================================

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for app EC2 instances. Allow inbound only from ALB."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-sg"
  })

  # セキュリティグループルールはライフサイクルの独立性を保つために別リソースで管理する。
  lifecycle {
    create_before_destroy = true
  }
}

# インバウンド: ALBのセキュリティグループからのアプリポートへのアクセスのみ許可する。
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow inbound from ALB security group."
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.alb_security_group_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-sg-ingress-alb"
  })
}

# アウトバウンド: パッケージ取得やAWS APIへのアクセスのためNATゲートウェイ経由で許可する。
resource "aws_vpc_security_group_egress_rule" "app_egress" {
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound traffic via NAT gateway."
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-sg-egress"
  })
}

# ==============================================================================
# IAMロール・ポリシー: 認証情報をインスタンスに持たせず、
# IAMロール経由でAWSサービスへのアクセスを付与する。
# ==============================================================================

# EC2インスタンスがAssumeRoleできるIAMロール。
# iam_instance_profile_arnが未指定の場合のみ作成する。
resource "aws_iam_role" "this" {
  count = local.create_iam ? 1 : 0

  name        = "${local.name_prefix}-app-role"
  description = "IAM role for app EC2 instances. Grants access to AWS services without storing credentials."
  path        = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-role"
  })
}

# SSM Session Manager経由のアクセスを可能にする。SSH鍵なしでのサーバー接続を実現する。
resource "aws_iam_role_policy_attachment" "ssm" {
  count = local.create_iam ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatchエージェントの使用を許可する。メトリクス・ログ収集に必要なポリシーをアタッチする。
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count = local.create_iam ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# 呼び出し側から追加ポリシーを注入できる。アプリ固有のS3アクセス等に使用する。
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = local.create_iam ? toset(var.additional_iam_policy_arns) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# インスタンスプロファイル: EC2インスタンスにIAMロールを紐付けるためのラッパー。
resource "aws_iam_instance_profile" "this" {
  count = local.create_iam ? 1 : 0

  name = "${local.name_prefix}-app-profile"
  role = aws_iam_role.this[0].name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-profile"
  })
}

# ==============================================================================
# Launch Template: インスタンスの起動設定を定義する。
# Launch Configurationは非推奨のため、Launch Templateを使用する。
# ==============================================================================

resource "aws_launch_template" "app" {
  name        = "${local.name_prefix}-app-lt"
  description = "Launch template for app EC2 instances."

  image_id      = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # ユーザーデータを指定された場合のみbase64エンコードして設定する。
  user_data = var.user_data != null ? base64encode(var.user_data) : null

  # IMDSv2を強制してSSRF攻撃によるメタデータ漏洩を防止する。
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # ルートボリュームの暗号化を有効にしてデータ保護を強化する。
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = var.root_volume_encrypted
      delete_on_termination = true
    }
  }

  # IAMインスタンスプロファイルを付与して、認証情報なしでAWSサービスにアクセスできるようにする。
  iam_instance_profile {
    arn = local.instance_profile_arn
  }

  # アプリ用セキュリティグループのみを割り当て、不要なアクセスを遮断する。
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
    delete_on_termination       = true
  }

  # Launch Templateの更新時に新バージョンを作成し、既存バージョンは保持する。
  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app-vol"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-lt"
  })
}

# ==============================================================================
# Auto Scaling Group: マルチAZ配置とALBヘルスチェックを組み合わせて
# 高可用性を実現する。
# ==============================================================================

resource "aws_autoscaling_group" "app" {
  name = "${local.name_prefix}-app-asg"

  # マルチAZ配置: 複数のプライベートサブネットを指定してAZ冗長性を確保する。
  vpc_zone_identifier = var.subnet_ids

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = local.asg_desired_capacity

  # ALBターゲットグループに登録して、ALB経由でトラフィックを受け取る。
  target_group_arns = var.target_group_arns

  # ALBのヘルスチェックを活用して、異常なインスタンスを自動的に置き換える。
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  termination_policies = var.termination_policies
  enabled_metrics      = var.enabled_metrics

  # 最新バージョンのLaunch Templateを使用する。
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # インスタンス更新時はローリングアップデートを行い、サービス停止を防ぐ。
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = var.health_check_grace_period
    }
  }

  # ASGリソース自体のタグと、ASGが起動するインスタンスに伝播するタグを一括設定する。
  dynamic "tag" {
    for_each = merge(local.common_tags, {
      Name = "${local.name_prefix}-app-asg"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [
      # 外部のスケーリングポリシーによる変更を無視して、Terraformの上書きを防ぐ。
      desired_capacity,
    ]
  }
}

# ==============================================================================
# Auto Scalingポリシー: CPU使用率に基づくスケールアウト・スケールインを定義する。
# ==============================================================================

# スケールアウトポリシー: CPU高負荷時にインスタンスを追加する。
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${local.name_prefix}-app-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# スケールアウトトリガー: CPU使用率が閾値を超えた場合にスケールアウトポリシーを実行する。
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-app-cpu-high"
  alarm_description   = "Trigger scale-out when CPU utilization exceeds threshold."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_out_cpu_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-cpu-high"
  })
}

# スケールインポリシー: CPU低負荷時に余剰インスタンスを削除してコストを最適化する。
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${local.name_prefix}-app-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# スケールイントリガー: CPU使用率が閾値を下回った場合にスケールインポリシーを実行する。
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.name_prefix}-app-cpu-low"
  alarm_description   = "Trigger scale-in when CPU utilization falls below threshold."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_in_cpu_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in.arn]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-cpu-low"
  })
}
