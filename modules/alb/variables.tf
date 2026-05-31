# ---------------------------------------------------------------------------
# 必須変数: 呼び出し側から必ず注入する値
# ---------------------------------------------------------------------------

variable "vpc_id" {
  description = "ALBを配置するVPCのID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALBを配置するパブリックサブネットIDのリスト（複数AZ推奨）"
  type        = list(string)
}

variable "app_sg_id" {
  description = "EC2インスタンスに付与されているSGのID。ALBからのインバウンドルールを追加する対象"
  type        = string
}

variable "acm_certificate_arn" {
  description = "HTTPS(443)リスナーに紐付けるACM証明書のARN"
  type        = string
}

variable "access_logs_bucket" {
  description = "ALBアクセスログを保存するS3バケット名。バケット自体はモジュール外で作成・管理すること"
  type        = string
}

# ---------------------------------------------------------------------------
# 任意変数: デフォルト値を持ち、呼び出し側での上書きが可能
# ---------------------------------------------------------------------------

variable "alb_name" {
  description = "ALBのリソース名"
  type        = string
  default     = "app-alb"
}

variable "target_port" {
  description = "ターゲットグループがトラフィックを転送するポート番号（EC2側）"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "ターゲットグループのヘルスチェックパス"
  type        = string
  default     = "/health"
}

variable "health_check_healthy_threshold" {
  description = "ヘルシーと判定するまでの連続成功回数"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "アンヘルシーと判定するまでの連続失敗回数"
  type        = number
  default     = 3
}

variable "health_check_interval" {
  description = "ヘルスチェック間隔（秒）"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "ヘルスチェックタイムアウト（秒）"
  type        = number
  default     = 5
}

variable "deregistration_delay" {
  description = "ターゲット登録解除前のドレイニング待機時間（秒）"
  type        = number
  default     = 300
}

variable "idle_timeout" {
  description = "ALBのアイドルタイムアウト（秒）"
  type        = number
  default     = 60
}

variable "ssl_policy" {
  description = "HTTPSリスナーに適用するSSLポリシー。最新の推奨ポリシーを使用すること"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "access_logs_prefix" {
  description = "S3バケット内のアクセスログ保存プレフィックス"
  type        = string
  default     = "alb"
}

variable "tags" {
  description = "各リソースへ追加でマージするタグ。local.common_tagsと合わせて使用"
  type        = map(string)
  default     = {}
}
