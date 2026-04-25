# --- Data Source ---
data "aws_region" "current" {}

# --------------------------------------------------------------------------------------------------
# VPC Endpoints (Gateway Type)
# Gateway型エンドポイントはルートテーブルに関連付けることで有効になる。
# 全層（public / app / db / management）のルートテーブルに適用し、
# NATを経由せずにS3・DynamoDBへアクセスできるようにする。
# --------------------------------------------------------------------------------------------------

locals {
  # 全層のルートテーブルIDをまとめる
  # count=0のリソースは[*]で空リストになるため、そのままconcatで安全に結合できる
  all_route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.app[*].id,
    aws_route_table.db[*].id,
    aws_route_table.management[*].id,
  )
}

# S3 エンドポイント
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = local.all_route_table_ids

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-s3-endpoint" }
  )
}

# DynamoDB エンドポイント
resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = local.all_route_table_ids

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-dynamodb-endpoint" }
  )
}