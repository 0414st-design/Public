terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # TODO: LABアカウント取得後にコメントアウトを解除して、以下の手順を実行する。
  # 1. terraform init (S3へのマイグレーション)
  # 2. DynamoDBによるロックが効いているか確認
  # backend "s3" {
  # bucket         = "mylab-tfstate"
  # key            = "lab/terraform.tfstate"
  # region         = "ap-northeast-1"
  # dynamodb_table = "mylab-tfstate-lock"
  # encrypt        = true
	# }
}