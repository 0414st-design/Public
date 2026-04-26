# --------------------------------------------------------------------------------------------------
# VPC Outputs
# これらは他のモジュール（EC2, ECS, Lambda等）がこのVPCを利用するために公開する「窓口」です。
# --------------------------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPCのID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPCのCIDRブロック"
  value       = aws_vpc.this.cidr_block
}

# --- Subnets ---

output "public_subnet_ids" {
  description = "パブリックサブネットのIDリスト"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "アプリ層（プライベート）サブネットのIDリスト"
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "データ層（プライベート）サブネットのIDリスト"
  value       = aws_subnet.db[*].id
}

output "management_subnet_ids" {
  description = "管理層サブネットのIDリスト（デフォルト空。使用時は management_subnet_offsets を指定）"
  value       = aws_subnet.management[*].id
}

# --- Route Tables ---

output "public_route_table_id" {
  description = "パブリック用ルートテーブルのID"
  value       = aws_route_table.public.id
}

output "app_route_table_ids" {
  description = "app層ルートテーブルのIDリスト"
  value       = aws_route_table.app[*].id
}

output "db_route_table_ids" {
  description = "db層ルートテーブルのIDリスト"
  value       = aws_route_table.db[*].id
}

output "management_route_table_ids" {
  description = "管理層ルートテーブルのIDリスト。variable 'management_subnet_offsets' を指定した場合のみ出力されます"
  value       = aws_route_table.management[*].id
}

# --- Security Groups (追記箇所) ---

output "web_sg_id" {
  description = "Web/ALB用セキュリティグループのID"
  value       = aws_security_group.web.id
}

output "app_sg_id" {
  description = "アプリ層用セキュリティグループのID"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "DB層用セキュリティグループのID"
  value       = aws_security_group.db.id
}