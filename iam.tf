# SSM Session Manager用IAMロール
# EC2インスタンスがSSMと通信するために必要。
# このロールを持つEC2はSSHキーなしでSession Managerから接続できる。

# --- IAMロール ---
# EC2がAWSサービスを呼び出す際に使用するロール。
# assume_role_policyでEC2サービスにこのロールの使用を許可する。
resource "aws_iam_role" "ssm" {
  name = "${local.project}-${local.environment}-ssm-role"

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

  tags = local.common_tags
}

# --- マネージドポリシーのアタッチ ---
# AmazonSSMManagedInstanceCore はSSMに必要な最小権限のAWSマネージドポリシー。
# Session Manager・パッチマネージャー・インベントリの利用に必要な権限が含まれる。
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- インスタンスプロファイル ---
# IAMロールをEC2に紐付けるためのラッパー。
# EC2はIAMロールを直接参照できないため、インスタンスプロファイル経由で紐付ける。
resource "aws_iam_instance_profile" "ssm" {
  name = "${local.project}-${local.environment}-ssm-profile"
  role = aws_iam_role.ssm.name

  tags = local.common_tags
}