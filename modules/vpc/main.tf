# 共通タグ（locals）
locals {
  common_tags = {
    Environment = var.environment # 変数から受け取るようにするとより柔軟です
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    { Name = var.vpc_name }
  )
}

# パブリックサブネット
resource "aws_subnet" "public" {
  # 以前は IPのリストの数 でしたが、これからは Offset(数字)のリストの数 になります
  count = length(var.public_subnet_offsets)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  # 【重要】cidr_block を自動計算に変更
  cidr_block = cidrsubnet(var.vpc_cidr, 8, var.public_subnet_offsets[count.index])

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-public-${count.index}" }
  )
}

# アプリ層のプライベートサブネット
resource "aws_subnet" "app" {
  count = length(var.app_subnet_offsets)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]

  # 【重要】cidr_block を自動計算に変更
  cidr_block = cidrsubnet(var.vpc_cidr, 8, var.app_subnet_offsets[count.index])

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-app-${count.index}" }
  )
}

# データ層のプライベートサブネット
resource "aws_subnet" "db" {
  count = length(var.db_subnet_offsets)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]

  # 【重要】cidr_block を自動計算に変更
  cidr_block = cidrsubnet(var.vpc_cidr, 8, var.db_subnet_offsets[count.index])

  tags = merge(
    local.common_tags,
    { Name = "${var.vpc_name}-db-${count.index}" }
  )
}