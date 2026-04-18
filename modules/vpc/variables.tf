variable "vpc_cidr" {
  description = "VPC全体のIP範囲"
  type        = string
  default     = "10.0.0.0/16"
}

# --- 自動計算用のインデックス (Offsets) ---
variable "public_subnet_offsets" {
  description = "パブリックサブネットに使用するインデックス"
  type        = list(number)
  default     = [1, 2]
}

variable "app_subnet_offsets" {
  description = "アプリサブネットに使用するインデックス"
  type        = list(number)
  default     = [11, 12]
}

variable "db_subnet_offsets" {
  description = "DBサブネットに使用するインデックス"
  type        = list(number)
  default     = [21, 22]
}

# --- 基本情報 ---
variable "vpc_name" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "project" {
  type = string
}

variable "enable_s3_endpoint" {
  description = "S3ゲートウェイエンドポイントを有効にするか"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "DynamoDBゲートウェイエンドポイントを有効にするか"
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "ログの保持日数（コストと調査のトレードオフ）"
  type        = number
  default     = 7 # 開発環境は1週間、本番は30日など使い分ける
}