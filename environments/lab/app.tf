# ------------------------------------------------------------------------------
# パターン1: 最小構成（必須変数のみ指定、IAMはモジュール内で自動作成）
# ------------------------------------------------------------------------------

module "app_compute" {
  source = "../../modules/app"

  # 識別子: リソース名・タグに使用する。
  env     = local.environment  # locals.tfで定義した環境識別子を参照する。
  project = local.project      # locals.tfで定義したサービス名を参照する。

  # ネットワーク: VPC・プライベートサブネットはvpcモジュールの出力値を参照する。
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids # 2つ以上のAZに跨るサブネットを指定する。

  # ALB連携: albモジュールの出力値を参照してセキュリティグループとターゲットグループを紐付ける。
  alb_security_group_id = module.alb.security_group_id
  target_group_arns     = [module.alb.target_group_arn]

  # 追加タグ: common_tagsとマージして全リソースに付与する。
  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# パターン2: 詳細構成（各種設定を明示的に指定する場合）
# ------------------------------------------------------------------------------

module "app_compute_full" {
  source = "../../modules/app"

  # 識別子。
  env     = local.environment
  project = local.project

  # ネットワーク。
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # ALB連携。
  alb_security_group_id = module.alb.security_group_id
  target_group_arns     = [module.alb.target_group_arn]

  # インスタンス設定: AMI IDを明示指定する場合はSSM取得をスキップする。
  instance_type = "t3.medium"
  ami_id        = "ami-0123456789abcdef0" # 固定AMIを使用する場合のみ指定する。省略時はSSMから最新AL2023を取得する。
  # key_name    = "my-keypair"            # SSM Session Manager使用時はキーペア不要のためコメントアウト推奨。

  # ストレージ設定。
  root_volume_size      = 30
  root_volume_type      = "gp3"
  root_volume_encrypted = true

  # セキュリティ設定: IMDSv2を強制してSSRF対策を施す。
  metadata_http_tokens = "required"

  # アプリケーション設定: 待ち受けポートを指定する。
  app_port = 8080

  # Auto Scaling設定: トラフィックパターンに合わせてmin/max/desiredを調整する。
  asg_min_size         = 2
  asg_max_size         = 8
  asg_desired_capacity = 2

  # ヘルスチェック: ALBのヘルスチェックを活用してインスタンスの健全性を管理する。
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # スケーリング閾値: アプリの特性に合わせて調整する。
  scale_out_cpu_threshold = 70
  scale_in_cpu_threshold  = 30

  # ユーザーデータ: アプリのインストール・起動スクリプトを指定する。
  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    dnf update -y
    dnf install -y amazon-cloudwatch-agent
    # アプリケーションのセットアップ処理をここに記述する。
  EOT

  # IAM設定: 外部で作成したIAMプロファイルを使用する場合のみ指定する。
  # 省略時はモジュール内でSSM Session Manager + CloudWatchAgentポリシーを付与したロールを自動作成する。
  # iam_instance_profile_arn = aws_iam_instance_profile.existing.arn

  # 追加IAMポリシー: モジュール内でIAMを作成する場合に追加でアタッチするポリシーを指定する。
  additional_iam_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess", # アプリがS3から設定ファイルを読み込む場合の例。
  ]

  # 追加タグ。
  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# 出力値の参照例: 他のリソースやモジュールからcomputeモジュールの値を参照する。
# ------------------------------------------------------------------------------

output "app_asg_name" {
  description = "アプリASGの名前。デプロイスクリプトやモニタリング設定で使用する。"
  value       = module.app_compute.autoscaling_group_name
}

output "app_security_group_id" {
  description = "アプリEC2のセキュリティグループID。DBモジュール等で許可元として参照する。"
  value       = module.app_compute.security_group_id
}

output "app_iam_role_arn" {
  description = "アプリEC2のIAMロールARN。外部からポリシーを追加する場合に参照する。"
  value       = module.app_compute.iam_role_arn
}
