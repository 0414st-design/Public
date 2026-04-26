variable "vpc_cidr" {
  description = "VPC全体のIP範囲 (将来の競合を避けるため 172.16系 /20 を推奨)"
  type        = string
  default     = "172.16.0.0/20"
}

# --- 自動計算用のインデックス (Offsets) ---
# /20 の VPC に対して /24 のサブネットを作る場合、Offsetは 0〜15 の範囲で指定します

variable "public_subnet_offsets" {
  description = "パブリックサブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト"
  type        = list(number)
  default     = [0, 1] # 172.16.0.0/24, 172.16.1.0/24
}

variable "app_subnet_offsets" {
  description = "アプリ層サブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト。"
  type        = list(number)
  default     = [4, 5] # 172.16.4.0/24, 172.16.5.0/24
}

variable "db_subnet_offsets" {
  description = "DB層サブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト。"
  type        = list(number)
  default     = [8, 9] # 172.16.8.0/24, 172.16.9.0/24
}

variable "management_subnet_offsets" {
  description = "管理層サブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト。踏み台・監視等に使用。不要な場合は [] を指定。指定時のみリソースが作成されます。"
  type        = list(number)
  default     = []
}

# --- EKS 設定 ---
variable "enable_eks" {
  description = "EKS用のサブネットタグを付与するかどうか。EKSクラスターを作成する場合はtrueにする。"
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "EKSクラスター名。enable_eks=trueの場合に必須（kubernetes.io/cluster/{name}タグに使用）。"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_eks || var.eks_cluster_name != ""
    error_message = "enable_eks=trueの場合、eks_cluster_nameを指定してください。"
  }
}

# --- 基本情報 ---
variable "vpc_name" {
  description = "VPCの名称 (タグやリソース名の接頭辞に使用)。"
  type        = string
}

variable "azs" {
  description = "使用するアベイラビリティゾーンのリスト。 (例: ['ap-northeast-1a', 'ap-northeast-1c'])"
  type        = list(string)
}

variable "environment" {
  description = "実行環境名 (例: dev, stg, prd)"
  type        = string

  # バリデーションの追加例：予期しない環境名が入るのを防ぐ。
  validation {
    condition     = contains(["dev", "stg", "prd", "lab"], var.environment)
    error_message = "環境名は dev, stg, prd, lab のいずれかである必要があります。"
  }
}

variable "project" {
  description = "プロジェクト名 (リソース識別用)"
  type        = string
}

variable "enable_s3_endpoint" {
  description = "S3ゲートウェイエンドポイントを作成するかどうか。"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "DynamoDBゲートウェイエンドポイントを作成するかどうか。"
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "VPCフローログ(CloudWatch Logs)の保持日数"
  type        = number
  default     = 7
}

# --- NAT Gateway 制御フラグ ---
variable "enable_nat_gateway" {
  description = "NAT Gatewayを作成し、プライベートサブネットからインターネットへの通信を可能にするか。" 
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "すべてのプライベートサブネットで1つのNAT Gatewayを共有し、コストを最小化するか。"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "可用性を高めるため、各AZに1つずつNAT Gatewayを作成するか。"
  # lab: false（single NATでコスト優先）
  # prd: true（AZ障害時の影響を局所化）
  type        = bool
  default     = false
}