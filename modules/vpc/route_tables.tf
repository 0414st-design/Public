# ルートテーブル
# 「どこ宛の通信を、どこに転送するか」を定義するもの。
# サブネットに関連付けることで、そのサブネット内のリソースに適用される。

# --------------------------------------------------------------------------------------------------
# パブリック用ルートテーブル
# 0.0.0.0/0（全インターネット）→ IGW へ転送
# --------------------------------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-public-rt"
  })
}

# デフォルトルート: インターネット向け通信をIGWへ
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# パブリックサブネット全てに関連付け
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_offsets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --------------------------------------------------------------------------------------------------
# app層 プライベートルートテーブル
# 0.0.0.0/0 → NAT GW へ転送（外部へのパッケージ取得等に必要）
#
# 作成数のロジック:
#   single_nat_gateway = true  → 1つだけ作成（全appサブネットで共有）
#   single_nat_gateway = false → AZ数分作成（各AZのNAT GWに対応）
#   enable_nat_gateway = false → NATなしでも1つ作成（ローカル通信用に必要）
# --------------------------------------------------------------------------------------------------

resource "aws_route_table" "app" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 1
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = var.single_nat_gateway ? "${var.vpc_name}-app-rt-shared" : "${var.vpc_name}-app-rt-${count.index}"
  })
}

# デフォルトルート: インターネット向け通信をNAT GWへ（NAT有効時のみ作成）
resource "aws_route" "app_nat_access" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  route_table_id         = aws_route_table.app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

# appサブネット全てに関連付け
# single_nat_gateway=true の場合は全appサブネットをindex 0（共有RT）に紐付ける
resource "aws_route_table_association" "app" {
  count          = length(var.app_subnet_offsets)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[var.single_nat_gateway ? 0 : count.index].id
}

# --------------------------------------------------------------------------------------------------
# db層 プライベートルートテーブル
# デフォルトルートなし（ローカル通信のみ）
# RDS・ElastiCacheはAWSマネージドのためインターネットへの経路が不要
# --------------------------------------------------------------------------------------------------

resource "aws_route_table" "db" {
  count  = length(var.db_subnet_offsets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-db-rt"
  })
}

# dbサブネット全てに関連付け（デフォルトルートなし＝完全閉域）
resource "aws_route_table_association" "db" {
  count          = length(var.db_subnet_offsets)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[0].id
}

# --------------------------------------------------------------------------------------------------
# management層 プライベートルートテーブル
# 0.0.0.0/0 → NAT GW へ転送（踏み台・監視・CI/CDランナーのパッケージ取得等に必要）
# management_subnet_offsets = [] の場合はリソース自体が作成されない
#
# 作成数のロジック:
#   single_nat_gateway = true  → 1つだけ作成（全managementサブネットで共有）
#   single_nat_gateway = false → AZ数分作成（各AZのNAT GWに対応）
# --------------------------------------------------------------------------------------------------

resource "aws_route_table" "management" {
  count  = length(var.management_subnet_offsets) > 0 ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = var.single_nat_gateway ? "${var.vpc_name}-management-rt-shared" : "${var.vpc_name}-management-rt-${count.index}"
  })
}

# デフォルトルート: インターネット向け通信をNAT GWへ（NAT有効かつmanagementサブネットが存在する場合のみ）
resource "aws_route" "management_nat_access" {
  count                  = length(var.management_subnet_offsets) > 0 && var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  route_table_id         = aws_route_table.management[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

# managementサブネット全てに関連付け
# single_nat_gateway=true の場合は全managementサブネットをindex 0（共有RT）に紐付ける
resource "aws_route_table_association" "management" {
  count          = length(var.management_subnet_offsets)
  subnet_id      = aws_subnet.management[count.index].id
  route_table_id = aws_route_table.management[var.single_nat_gateway ? 0 : count.index].id
}