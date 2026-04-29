# 作ったモジュールを呼びだす
module "my_vpc" {
  source = "./modules/vpc"

  # VPCの全体範囲
  vpc_cidr = "172.16.0.0/20"
  vpc_name = "my-vpc"

  # 使用するAZの指定
  azs = ["ap-northeast-1a", "ap-northeast-1c"]

  # IPアドレスを直接書くのではなく、何番目の区画(Offset)を使うか数字で指定する。
  public_subnet_offsets = [0, 1]  # 172.16.0.0/24, 172.16.1.0/24
  app_subnet_offsets    = [4, 5]  # 172.16.4.0/24, 172.16.5.0/24
  db_subnet_offsets     = [8, 9]  # 172.16.8.0/24, 172.16.9.0/24

  # --- NAT Gateway 設定 ---
  # まずはコストを抑えた「Single NAT Gateway」構成に設定しています
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # エンドポイント設定
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # タグ用の変数
  project     = local.project
  environment = local.environment
}