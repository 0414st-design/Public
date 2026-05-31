locals {
  project     = "mylab"
  environment = "lab"

  # すべてのリソースで共通して使いたいタグ
  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
  }

  # ALB関連: モジュール外で管理するリソースの参照値
  alb_acm_arn        = "arn:aws:acm:ap-northeast-1:123456789012:certificate/xxxx-xxxx"
  alb_logs_bucket    = "mylab-alb-access-logs-lab"
}