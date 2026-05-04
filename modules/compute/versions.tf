# モジュールが必要とするプロバイダーのバージョン制約
# このモジュールを単体で再利用する際に、互換性を保証するために明示する。
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}