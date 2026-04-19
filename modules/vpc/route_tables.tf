# --- Public Route Table ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-public-rt"
  })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_offsets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Private Route Tables ---

resource "aws_route_table" "private" {
  # NAT有効時は構成に応じた数、無効時は1つ作成
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 1
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = var.single_nat_gateway ? "${var.vpc_name}-private-rt-shared" : "${var.vpc_name}-private-rt-${count.index}"
  })
}

resource "aws_route" "private_nat_access" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "app" {
  count          = length(var.app_subnet_offsets)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "db" {
  count          = length(var.db_subnet_offsets)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}