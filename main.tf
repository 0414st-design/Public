# AWSを使うための宣言（プロバイダー）
provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

# 作ったモジュールを呼びだす
module "my_vpc" {
  source = "./modules/vpc"

  # VPCの全体範囲（ここを変えるだけでサブネットも連動します）
  vpc_cidr = "10.0.0.0/16"
  vpc_name = "my-vpc"

  # 使用するAZの指定
  azs = ["ap-northeast-1a", "ap-northeast-1c"]

  # 【変更点】IPアドレスを直接書くのではなく、何番目の区画(Offset)を使うか数字で指定
  # ※モジュール内の cidrsubnet(var.vpc_cidr, 8, offset) で計算されます
  public_subnet_offsets = [1, 2]   # 10.0.1.0/24, 10.0.2.0/24 相当
  app_subnet_offsets    = [11, 12] # 10.0.11.0/24, 10.0.12.0/24 相当
  db_subnet_offsets     = [21, 22] # 10.0.21.0/24, 10.0.22.0/24 相当

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # タグ用の変数
  environment = "lab"
  project     = "mylab"
}

