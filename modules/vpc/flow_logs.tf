# 1. ログの保管先（CloudWatch Logs）
# ロググループ名にプロジェクト名と環境名を含め、管理画面での識別性を向上させる。
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project}/${var.environment}/${var.vpc_name}"
  retention_in_days = var.flow_log_retention_days

  tags = local.common_tags
}

# 2. VPCフローログの設定
# VPC内の全トラフィックを対象にログを記録し、CloudWatch Logs へ転送する。
resource "aws_flow_log" "this" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    { Name = "${var.project}-${var.environment}-${var.vpc_name}-flow-logs" }
  )
}

# 3. IAMロール
# 同一アカウント内での名前衝突を防ぐため、プロジェクト名と環境名を名前に含める。
resource "aws_iam_role" "vpc_flow_log_role" {
  name = "${var.project}-${var.environment}-${var.vpc_name}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

# 4. IAMポリシー
# フローログを CloudWatch Logs に書き込むための最小限の権限を、インラインポリシーで定義する。
resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "${var.project}-${var.environment}-${var.vpc_name}-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      # 権限の範囲を、作成した特定のロググループ配下のリソースに限定する。
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
    }]
  })
}