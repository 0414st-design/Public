# --------------------------------------------------------------------------------------------------
# VPC Endpoints (Gateway Type)
# --------------------------------------------------------------------------------------------------

# S3 エンドポイント (Gateway型)
# NAT Gateway経由の通信を避け、コストを削減しつつセキュリティを向上させます。
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"

  # 関連付けるルートテーブル
  # パブリックとプライベート（App/DB）の両方に紐付けておくのが一般的です。
  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-s3-endpoint" }
  )
}

# DynamoDB エンドポイント (Gateway型)
# S3と同様、無料でプライベート通信を可能にします。
resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.ap-northeast-1.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-dynamodb-endpoint" }
  )
}