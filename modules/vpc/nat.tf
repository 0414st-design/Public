# NAT Gateway用のElastic IP
resource "aws_eip" "nat" {
  # 論理：NATが必要な数だけ作成
  count = var.enable_nat_gateway ? (
    var.single_nat_gateway ? 1 : (
      var.one_nat_gateway_per_az ? length(var.azs) : length(var.public_subnet_offsets)
    )
  ) : 0

  # 最新のAWS Provider (v5.0+) 推奨の記述
  domain = "vpc"

  tags = merge(
    local.common_tags, # 
    { Name = "${var.vpc_name}-nat-eip-${count.index}" }
  )
}

# NAT Gateway本体
resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? (
    var.single_nat_gateway ? 1 : (
      var.one_nat_gateway_per_az ? length(var.azs) : length(var.public_subnet_offsets)
    )
  ) : 0

  allocation_id = aws_eip.nat[count.index].id
  
  # 配置するサブネットの指定
  # single_nat_gateway = true の場合は常に 1つ目(index 0) のパブリックサブネットに作成されます
  subnet_id = aws_subnet.public[count.index].id # [cite: 4]

  tags = merge(
    local.common_tags, # [cite: 3, 5]
    { Name = "${var.vpc_name}-nat-${count.index}" }
  )

  # 明示的な依存関係（EIPができてからNATGWを作る）
  depends_on = [aws_internet_gateway.this] # 
}