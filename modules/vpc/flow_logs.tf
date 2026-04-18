# 1. ログの保管先（CloudWatch Logs Group）
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.vpc_name}"
  retention_in_days = var.flow_log_retention_days # 保存期間を変数で制御

  tags = local.common_tags
}

# 2. VPCフローログの設定
resource "aws_flow_log" "this" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL" # REJECTのみに絞ることも可能
  vpc_id          = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-flow-logs" })
}

# 3. VPCがログを書き込むためのIAMロール
resource "aws_iam_role" "vpc_flow_log_role" {
  name = "${var.vpc_name}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

# 4. IAMロールに権限を付与
resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "${var.vpc_name}-flow-log-policy"
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
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}