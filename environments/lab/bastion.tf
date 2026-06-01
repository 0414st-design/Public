# Computeモジュールの呼び出し
# SSM対応の踏み台EC2をmanagement層に配置する。
# management_subnet_offsets = [] の場合はサブネットが存在しないため、
# 実際に使用する際は必ずサブネットを1つ以上指定すること。

module "bastion" {
  source = "../../modules/bastion"

  # --- 基本設定 ---
  instance_name = "${local.project}-${local.environment}-bastion"
  instance_type = "t3.micro"

  # --- ネットワーク設定 ---
  # VPCモジュールのoutputからmanagement層の最初のサブネットを指定する。
  subnet_id          = module.my_vpc.management_subnet_ids[0]
  security_group_ids = [module.my_vpc.management_sg_id]

  # --- IAM設定 ---
  # iam.tfで定義したSSMインスタンスプロファイルを紐付ける。
  iam_instance_profile_name = aws_iam_instance_profile.ssm.name

  # --- ストレージ設定 ---
  root_volume_size = 20
  root_volume_type = "gp3"

  # --- タグ設定 ---
  # ルートのlocals.tfで定義した共通タグを渡す。
  tags = local.common_tags
}