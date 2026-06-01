# ==============================================================================
# 必須変数: 環境ごとに異なる値を呼び出し側から注入する。
# ==============================================================================

variable "env" {
  description = "環境識別子（例: dev, stg, prd）。リソース名・タグに使用する。"
  type        = string
}

variable "project" {
  description = "プロジェクト名またはシステム名。リソース名・タグに使用する。"
  type        = string
}

variable "vpc_id" {
  description = "EC2およびセキュリティグループを配置するVPCのID。"
  type        = string
}

variable "subnet_ids" {
  description = "EC2を配置するプライベートサブネットIDのリスト。マルチAZ構成のため2つ以上を指定する。"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "マルチAZ構成のため、subnet_idsは2つ以上のサブネットIDを指定する必要がある。"
  }
}

variable "alb_security_group_id" {
  description = "ALBのセキュリティグループID。インバウンドルールの許可元として使用する。"
  type        = string
}

variable "target_group_arns" {
  description = "ASGに紐付けるALBターゲットグループARNのリスト。"
  type        = list(string)
}

# ==============================================================================
# 任意変数（インスタンス設定）: デフォルト値はセキュリティ・可用性を考慮して設定する。
# ==============================================================================

variable "instance_type" {
  description = "EC2インスタンスタイプ。"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "使用するAMIのID。未指定の場合はSSMパラメータストアから最新のAmazon Linux 2023 AMIを自動取得する。"
  type        = string
  default     = null
}

variable "key_name" {
  description = "EC2インスタンスに割り当てるSSHキーペア名。未指定の場合はキーペアを設定しない（SSM Session Manager経由での接続を推奨）。"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "ルートボリュームのサイズ（GiB）。"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "ルートボリュームのEBSタイプ。"
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "ルートボリュームの暗号化を有効にするか否か。"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "EC2起動時に実行するユーザーデータスクリプト（base64エンコード不要）。"
  type        = string
  default     = null
}

variable "metadata_http_tokens" {
  description = "IMDSv2の強制設定。セキュリティ上の理由からrequiredを推奨する。"
  type        = string
  default     = "required"

  validation {
    condition     = contains(["required", "optional"], var.metadata_http_tokens)
    error_message = "metadata_http_tokensはrequiredまたはoptionalを指定する必要がある。"
  }
}

# ==============================================================================
# 任意変数（Auto Scaling設定）: トラフィックパターンに合わせて調整する。
# ==============================================================================

variable "asg_min_size" {
  description = "Auto Scalingグループの最小インスタンス数。"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Auto Scalingグループの最大インスタンス数。"
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "Auto Scalingグループの希望インスタンス数。未指定の場合はasg_min_sizeと同じ値を使用する。"
  type        = number
  default     = null
}

variable "health_check_grace_period" {
  description = "インスタンス起動後にヘルスチェックを開始するまでの猶予期間（秒）。アプリの起動時間に合わせて調整する。"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "ヘルスチェックの種別。ALBを使用する場合はELBを指定してALBヘルスチェックを活用する。"
  type        = string
  default     = "ELB"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_typeはEC2またはELBを指定する必要がある。"
  }
}

variable "termination_policies" {
  description = "スケールイン時のインスタンス終了ポリシー。"
  type        = list(string)
  default     = ["OldestLaunchTemplate", "OldestInstance"]
}

variable "enabled_metrics" {
  description = "CloudWatchで収集するASGメトリクスのリスト。"
  type        = list(string)
  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]
}

variable "scale_out_cpu_threshold" {
  description = "スケールアウトをトリガーするCPU使用率の閾値（%）。"
  type        = number
  default     = 70
}

variable "scale_in_cpu_threshold" {
  description = "スケールインをトリガーするCPU使用率の閾値（%）。"
  type        = number
  default     = 30
}

# ==============================================================================
# 任意変数（セキュリティグループ設定）: アプリが待ち受けるポートを指定する。
# ==============================================================================

variable "app_port" {
  description = "アプリケーションが待ち受けるポート番号。ALBからのインバウンドトラフィックを許可する。"
  type        = number
  default     = 80
}

variable "egress_cidr_blocks" {
  description = "アウトバウンドトラフィックを許可するCIDRブロックのリスト。パッケージ取得等のためインターネットへのアクセスを許可する（NATゲートウェイ経由）。"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ==============================================================================
# 任意変数（IAMロール設定）: 外部で作成したロールを使用する場合はARNを指定する。
# ==============================================================================

variable "iam_instance_profile_arn" {
  description = "既存のIAMインスタンスプロファイルARN。指定した場合はモジュール内でのIAMリソース作成をスキップする。"
  type        = string
  default     = null
}

variable "additional_iam_policy_arns" {
  description = "モジュール内でIAMロールを作成する場合に追加でアタッチするIAMマネージドポリシーARNのリスト。"
  type        = list(string)
  default     = []
}

# ==============================================================================
# 任意変数（タグ設定）: 全リソースにマージして適用する共通タグ。
# ==============================================================================

variable "tags" {
  description = "全リソースに付与する追加タグ。common_tagsにマージして適用する。"
  type        = map(string)
  default     = {}
}
