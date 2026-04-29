locals {
  project     = "mylab"
  environment = "lab"

  # すべてのリソースで共通して使いたいタグ
  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}