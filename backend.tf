terraform {
  # TODO: LABアカウント取得後にコメントアウトを解除して、以下の手順を実行する。
  # 1. terraform init (S3へのマイグレーション)
  # 2. DynamoDBによるロックが効いているか確認
  # backend "s3" {
  # bucket         = "mylab-tfstate"
  # key            = "vpc/terraform.tfstate"
  # region         = "ap-northeast-1"
  # dynamodb_table = "mylab-tfstate-lock"
  # encrypt        = true
	# }
}