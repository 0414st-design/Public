output "instance_id" {
  description = "EC2インスタンスのID。他のリソースから参照する際に使用する。"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "EC2インスタンスのプライベートIPアドレス。SSM接続時の確認や監視設定に使用する。"
  value       = aws_instance.this.private_ip
}

output "instance_name" {
  description = "EC2インスタンスの名前。ログや監視ツールでの識別に使用する。"
  value       = var.instance_name
}