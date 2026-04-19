terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# AWSを使うための宣言（プロバイダー）
provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

# 作ったモジュールを呼びだす
module "my_vpc" {
  source = "./modules/vpc"

  # VPCの全体範囲
  vpc_cidr = "10.0.0.0/16"
  vpc_name = "my-vpc"

  # 使用するAZの指定
  azs = ["ap-northeast-1a", "ap-northeast-1c"]

  # IPアドレスを直接書くのではなく、何番目の区画(Offset)を使うか数字で指定
  public_subnet_offsets = [1, 2]   # 10.0.1.0/24, 10.0.2.0/24 相当
  app_subnet_offsets    = [11, 12] # 10.0.11.0/24, 10.0.12.0/24 相当
  db_subnet_offsets     = [21, 22] # 10.0.21.0/24, 10.0.22.0/24 相当

  # --- NAT Gateway 設定 (追記箇所) ---
  # まずはコストを抑えた「Single NAT Gateway」構成に設定しています
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # エンドポイント設定（既存）
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # タグ用の変数
  environment = "lab"
  project     = "mylab"
}