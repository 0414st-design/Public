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