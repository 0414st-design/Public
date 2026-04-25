# Internet Gateway
# VPCとインターネットを繋ぐ出入口。パブリックサブネットの通信はここを経由する。
# VPCに1つだけ作成する（複数作成不可）

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-igw" }
  )
}