# 共通タグ（locals）
# すべてのリソースに merge() で付与することで、タグの一元管理を実現する
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }

  # EKS用タグ
  # enable_eks=true かつ eks_cluster_name が指定されている場合のみ付与する
  # kubernetes.io/cluster/{name}: EKSがサブネットを認識するために必要
  eks_public_tags = var.enable_eks ? {
    "kubernetes.io/role/elb"                          = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}"   = "shared"
  } : {}

  eks_private_tags = var.enable_eks ? {
    "kubernetes.io/role/internal-elb"                 = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}"   = "shared"
  } : {}
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # Route53やECSのサービスディスカバリに必要

  tags = merge(
    local.common_tags,
    { Name = var.vpc_name }
  )
}

# パブリックサブネット
resource "aws_subnet" "public" {
  # Offsetリストの要素数がそのままサブネットの作成数になる（例: [1, 2] → 2つ）
  count = length(var.public_subnet_offsets)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true # パブリックサブネットはEC2起動時にパブリックIPを自動付与

  # vpc_cidrを/24に分割し、Offsetの番号をサブネット番号として使う
  # 例: vpc_cidr=10.0.0.0/16, offset=1 → 10.0.1.0/24
  cidr_block = cidrsubnet(var.vpc_cidr, 8, var.public_subnet_offsets[count.index])

  tags = merge(
    local.common_tags,
    local.eks_public_tags,
    { Name = "${var.vpc_name}-public-${var.azs[count.index]}" }
  )
}

# アプリ層のプライベートサブネット
resource "aws_subnet" "app" {
  # Offsetリストの要素数がそのままサブネットの作成数になる（例: [11, 12] → 2つ）
  count = length(var.app_subnet_offsets)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]

  # 例: vpc_cidr=10.0.0.0/16, offset=11 → 10.0.11.0/24
  cidr_block = cidrsubnet(var.vpc_cidr, 8, var.app_subnet_offsets[count.index])

  tags = merge(
    local.common_tags,
    local.eks_private_tags,
    { Name = "${var.vpc_name}-app-${var.azs[count.index]}" }
  )
}

# データ層のプライベートサブネット
resource "aws_subnet" "db" {
  # Offsetリストの要素数がそのままサブネットの作成数になる（例: [21, 22] → 2つ）
  count = length(var.db_subnet_offsets)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]

  # 例: vpc_cidr=10.0.0.0/16, offset=21 → 10.0.21.0/24
  cidr_block = cidrsubnet(var.vpc_cidr, 8, var.db_subnet_offsets[count.index])

  tags = merge(
    local.common_tags,
    # db層はEKSのワーカーノード・ALB配置対象外のためEKSタグは付与しない
    { Name = "${var.vpc_name}-db-${var.azs[count.index]}" }
  )
}

# 管理層のプライベートサブネット
resource "aws_subnet" "management" {
  # Offsetリストの要素数がそのままサブネットの作成数になる（[] なら0個=作成しない）
  count = length(var.management_subnet_offsets)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]

  # 例: vpc_cidr=10.0.0.0/16, offset=31 → 10.0.31.0/24
  cidr_block = cidrsubnet(var.vpc_cidr, 8, var.management_subnet_offsets[count.index])

  tags = merge(
    local.common_tags,
    # management層はEKSのワーカーノード・ALB配置対象外のためEKSタグは付与しない
    { Name = "${var.vpc_name}-management-${var.azs[count.index]}" }
  )
}
