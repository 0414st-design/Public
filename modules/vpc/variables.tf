variable "vpc_cidr" {
  description = "VPC全体のIP範囲 (例: 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
}

# --- 自動計算用のインデックス (Offsets) ---
variable "public_subnet_offsets" {
  description = "パブリックサブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト"
  type        = list(number)
  default     = [1, 2]
}

variable "app_subnet_offsets" {
  description = "アプリ層サブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト"
  type        = list(number)
  default     = [11, 12]
}

variable "db_subnet_offsets" {
  description = "DB層サブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト"
  type        = list(number)
  default     = [21, 22]
}

variable "management_subnet_offsets" {
  description = "管理層サブネットのOffsetリスト。踏み台・監視・CI/CDランナー等に使用。不要な場合は [] を指定（NAT GW経由でインターネットに接続）"
  type        = list(number)
  default     = []
}

# --- EKS 設定 ---
variable "enable_eks" {
  description = "EKS用のサブネットタグを付与するかどうか。EKSクラスターを作成する場合はtrueにする"
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "EKSクラスター名。enable_eks=trueの場合に必須（kubernetes.io/cluster/{name}タグに使用）"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_eks || var.eks_cluster_name != ""
    error_message = "enable_eks=trueの場合、eks_cluster_nameを指定してください。"
  }
}

# --- 基本情報 ---
variable "vpc_name" {
  description = "VPCの名称 (タグやリソース名の接頭辞に使用)"
  type        = string
}

variable "azs" {
  description = "使用するアベイラビリティゾーンのリスト (例: ['ap-northeast-1a', 'ap-northeast-1c'])"
  type        = list(string)
}

variable "environment" {
  description = "実行環境名 (例: dev, stg, prd)"
  type        = string

  # バリデーションの追加例：予期しない環境名が入るのを防ぐ
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
  description = "S3ゲートウェイエンドポイントを作成するかどうか"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "DynamoDBゲートウェイエンドポイントを作成するかどうか"
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
  description = "NAT Gatewayを作成し、プライベートサブネットからインターネットへの通信を可能にするか" 
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "すべてのプライベートサブネットで1つのNAT Gatewayを共有し、コストを最小化するか"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "可用性を高めるため、各AZに1つずつNAT Gatewayを作成するか"
  # lab: false（single NATでコスト優先）
  # prd: true（AZ障害時の影響を局所化）
  type        = bool
  default     = false
}