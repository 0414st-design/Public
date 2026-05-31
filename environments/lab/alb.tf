# ---------------------------------------------------------------------------
# ALBモジュール呼び出しサンプル: environments/lab/alb.tf
#
# 前提:
#   - locals.tf に common_tags, env, project 等が定義済みであること
#   - vpc.tf   でVPCモジュールを呼び出し済みで outputs が参照可能であること
#   - compute.tf でcomputeモジュールを呼び出し済みで app_sg_id が参照可能であること
#   - ACM証明書は事前にAWSコンソール or 別モジュールで発行済みであること
#   - アクセスログ用S3バケットは別途（例: s3モジュール）で作成済みであること
# ---------------------------------------------------------------------------

module "alb" {
  source = "../../modules/alb"

  # --- 必須変数 ---
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  app_sg_id           = module.compute.app_sg_id
  acm_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  access_logs_bucket  = "my-project-alb-access-logs-lab"

  # --- 任意変数（環境ごとに上書き） ---
  alb_name           = "${local.project}-${local.env}-alb"
  target_port        = 8080
  health_check_path  = "/health"
  access_logs_prefix = "${local.project}/${local.env}/alb"

  # --- タグ: locals.tf の common_tags をそのまま渡す ---
  tags = local.common_tags
}
