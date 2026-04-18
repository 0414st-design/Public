resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id

  # public サブネットをすべて関連付け
  subnet_ids = [
    for s in aws_subnet.public : s.id
  ]

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-public-nacl" }
  )
}

# Ingress（受信）: 全許可
resource "aws_network_acl_rule" "public_ingress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1"          # 全プロトコル
  rule_action    = "allow"
  egress         = false         # ingress
  cidr_block     = "0.0.0.0/0"
}

# Egress（送信）: 全許可
resource "aws_network_acl_rule" "public_egress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true          # egress
  cidr_block     = "0.0.0.0/0"
}
