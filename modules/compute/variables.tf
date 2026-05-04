# --- 基本設定 ---
variable "instance_name" {
  description = "EC2インスタンスの名前（Nameタグに使用）"
  type        = string
}

variable "instance_type" {
  description = "EC2インスタンスタイプ（例: t3.micro）"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "使用するAMIのID。未指定の場合は最新のAmazon Linux 2023を自動取得する。"
  type        = string
  default     = ""
}

# --- ネットワーク設定 ---
variable "subnet_id" {
  description = "EC2を配置するサブネットのID（VPCモジュールのoutputから渡す。）"
  type        = string
}

variable "security_group_ids" {
  description = "EC2に紐付けるセキュリティグループIDのリスト"
  type        = list(string)
}

# --- IAM設定 ---
variable "iam_instance_profile_name" {
  description = "EC2に紐付けるIAMインスタンスプロファイル名（SSM接続に必要）"
  type        = string
}

# --- ストレージ設定 ---
variable "root_volume_size" {
  description = "ルートボリュームのサイズ（GB）"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "ルートボリュームのタイプ（gp3推奨）"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "root_volume_typeはgp2、gp3、io1、io2のいずれかを指定してください。"
  }
}

# --- タグ設定 ---
variable "common_tags" {
  description = "全リソースに付与する共通タグ（ルートのlocals.tfから渡す。）"
  type        = map(string)
  default     = {}
}