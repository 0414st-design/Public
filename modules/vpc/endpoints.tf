# --- Data Source ---
data "aws_region" "current" {}

# --------------------------------------------------------------------------------------------------
# VPC Endpoints (Gateway Type)
# --------------------------------------------------------------------------------------------------

# S3 エンドポイント
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  # 【修正】.name から .id に変更
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-s3-endpoint" }
  )
}

# DynamoDB エンドポイント
resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  # 【修正】.name から .id に変更
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
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