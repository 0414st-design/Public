# --- Data Source ---
# ami_idが未指定の場合、最新のAmazon Linux 2023を自動取得する。
# 指定がある場合はそちらを優先するため、count で制御する。
data "aws_ami" "amazon_linux_2023" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  # ami_idが指定されている場合はそちらを使い、未指定の場合はData Sourceで取得したIDを使う。
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023[0].id
}

# --- EC2インスタンス ---
resource "aws_instance" "this" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile_name

  # SSM Session Manager経由で接続するためSSHキーは不要
  # キーペアを持たないことで攻撃面を減らす。
  key_name = null

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true # ストレージの暗号化を有効化
    delete_on_termination = true # インスタンス削除時にボリュームも削除
  }

  # SSMエージェントはAmazon Linux 2023にデフォルトでインストール済み。
  # user_dataは原則不要だが、追加設定が必要な場合はここに記述する。
  user_data = null

  tags = merge(
    var.tags,
    { Name = var.instance_name }
  )

  # ルートボリュームのタグも統一する。
  volume_tags = merge(
    var.tags,
    { Name = "${var.instance_name}-root" }
  )
}