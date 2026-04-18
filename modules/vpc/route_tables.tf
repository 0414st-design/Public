resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-public-rt" }
  )
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  # 【ここを修正】cidrs から offsets に変更
  count          = length(var.public_subnet_offsets)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Private Route Tables ---

# アプリ層・データ層で共通のルートテーブル（必要に応じて分けても良いですが、まずは共通でOK）
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-private-rt" }
  )
}

# Appサブネットとの紐付け
resource "aws_route_table_association" "app" {
  count          = length(var.app_subnet_offsets)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private.id
}

# DBサブネットとの紐付け
resource "aws_route_table_association" "db" {
  count          = length(var.db_subnet_offsets)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.private.id
}