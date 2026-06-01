# ==============================================================================
# outputs: 呼び出し側のroot moduleや他のモジュールから参照できる値を公開する。
# ==============================================================================

# セキュリティグループ
output "security_group_id" {
  description = "アプリEC2インスタンスに紐付いたセキュリティグループのID。"
  value       = aws_security_group.app.id
}

output "security_group_arn" {
  description = "アプリEC2インスタンスに紐付いたセキュリティグループのARN。"
  value       = aws_security_group.app.arn
}

# IAMリソース（モジュール内で作成した場合のみ値を持つ）
output "iam_role_arn" {
  description = "EC2インスタンスに割り当てたIAMロールのARN。モジュール内でIAMを作成しなかった場合はnull。"
  value       = local.create_iam ? aws_iam_role.this[0].arn : null
}

output "iam_role_name" {
  description = "EC2インスタンスに割り当てたIAMロール名。モジュール内でIAMを作成しなかった場合はnull。"
  value       = local.create_iam ? aws_iam_role.this[0].name : null
}

output "instance_profile_arn" {
  description = "EC2インスタンスプロファイルのARN。外部指定の場合はその値、モジュール内作成の場合は作成されたプロファイルのARN。"
  value       = local.instance_profile_arn
}

# Launch Template
output "launch_template_id" {
  description = "Launch TemplateのID。"
  value       = aws_launch_template.app.id
}

output "launch_template_latest_version" {
  description = "Launch Templateの最新バージョン番号。"
  value       = aws_launch_template.app.latest_version
}

# Auto Scaling Group
output "autoscaling_group_id" {
  description = "Auto Scaling GroupのID（名前と同値）。"
  value       = aws_autoscaling_group.app.id
}

output "autoscaling_group_name" {
  description = "Auto Scaling Groupの名前。"
  value       = aws_autoscaling_group.app.name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling GroupのARN。"
  value       = aws_autoscaling_group.app.arn
}

# CloudWatchアラーム
output "cloudwatch_alarm_cpu_high_arn" {
  description = "CPUスケールアウトトリガー用CloudWatchアラームのARN。"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "cloudwatch_alarm_cpu_low_arn" {
  description = "CPUスケールイントリガー用CloudWatchアラームのARN。"
  value       = aws_cloudwatch_metric_alarm.cpu_low.arn
}

# 解決済みAMI ID（デバッグ・確認用）
output "resolved_ami_id" {
  description = "実際に使用しているAMI ID。変数指定またはSSM取得のいずれかの解決結果。"
  value       = local.ami_id
}
