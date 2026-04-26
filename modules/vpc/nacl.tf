# Network ACL（NACL）
# サブネット単位で適用するステートレスなファイアウォール。
# ステートレスのため、インバウンドとアウトバウンドを両方明示的に定義する必要がある。

resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id

  # publicサブネットをすべて関連付け
  subnet_ids = [
    for s in aws_subnet.public : s.id
  ]

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-public-nacl" }
  )
}

# Ingress（受信）: 全許可
# ALBへのHTTP/HTTPSなど、外部からの通信を受け付ける
resource "aws_network_acl_rule" "public_ingress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1" # 全プロトコル
  rule_action    = "allow"
  egress         = false # ingress
  cidr_block     = "0.0.0.0/0"
}

# Egress（送信）: 全許可
# レスポンスの返却やNAT経由のアウトバウンドを許可する
resource "aws_network_acl_rule" "public_egress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true # egress
  cidr_block     = "0.0.0.0/0"
}

# --------------------------------------------------------------------------------------------------
# App 層 NACL
# 役割: VPC 外からの直接アクセスをサブネット単位で遮断するゾーン境界の壁
# ポート単位の細かい制御は SG に委譲し、NACL は粗いフィルタに徹する
# --------------------------------------------------------------------------------------------------
resource "aws_network_acl" "app" {
  count      = length(var.app_subnet_offsets) > 0 ? 1 : 0
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.app : s.id]

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-app-nacl" })
}

resource "aws_network_acl_rule" "app_ingress_from_vpc" {
  count          = length(var.app_subnet_offsets) > 0 ? 1 : 0
  network_acl_id = aws_network_acl.app[0].id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "app_egress_to_vpc" {
  count          = length(var.app_subnet_offsets) > 0 ? 1 : 0
  network_acl_id = aws_network_acl.app[0].id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "app_egress_internet" {
  count          = var.enable_nat_gateway && length(var.app_subnet_offsets) > 0 ? 1 : 0
  network_acl_id = aws_network_acl.app[0].id
  rule_number    = 200
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# --------------------------------------------------------------------------------------------------
# DB 層 NACL
# 役割: app サブネット以外からの接続を明示的に遮断する
# ルートテーブル（デフォルトルートなし）との組み合わせで DB 層を二重に閉域化する
# ingress は app_subnet_cidrs を動的計算して許可。app サブネットを増やしても自動追従する
# --------------------------------------------------------------------------------------------------
resource "aws_network_acl" "db" {
  count      = length(var.db_subnet_offsets) > 0 ? 1 : 0
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.db : s.id]

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-db-nacl" })
}

resource "aws_network_acl_rule" "db_ingress_from_app" {
  for_each = {
    for idx, cidr in local.app_subnet_cidrs :
    idx => cidr
    if length(var.db_subnet_offsets) > 0
  }

  network_acl_id = aws_network_acl.db[0].id
  rule_number    = 100 + each.key
  protocol       = "-1"
  rule_action    = "allow"
  egress         = false
  cidr_block     = each.value
}

resource "aws_network_acl_rule" "db_egress_to_app" {
  for_each = {
    for idx, cidr in local.app_subnet_cidrs :
    idx => cidr
    if length(var.db_subnet_offsets) > 0
  }

  network_acl_id = aws_network_acl.db[0].id
  rule_number    = 100 + each.key
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  from_port      = 1024
  to_port        = 65535
  cidr_block     = each.value
}