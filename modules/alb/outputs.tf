# ---------------------------------------------------------------------------
# 出力値: 他モジュール（compute等）やルートモジュールから参照する値を公開する
# ---------------------------------------------------------------------------

output "alb_arn" {
  description = "ALBのARN。ルールやWAF等の紐付けに使用する"
  value       = aws_lb.alb.arn
}

output "alb_dns_name" {
  description = "ALBのDNS名。Route53レコードのaliasターゲットとして使用する"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "ALBのホストゾーンID。Route53のaliasレコード設定に必要"
  value       = aws_lb.alb.zone_id
}

output "alb_sg_id" {
  description = "ALBに付与したセキュリティグループのID。追加ルールの参照等に使用する"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "ターゲットグループのARN。Auto ScalingグループへのアタッチやECSサービスの設定に使用する"
  value       = aws_lb_target_group.tg.arn
}

output "target_group_name" {
  description = "ターゲットグループ名。CloudWatchメトリクスの参照等に使用する"
  value       = aws_lb_target_group.tg.name
}

output "listener_http_arn" {
  description = "HTTP(80)リスナーのARN。リスナールール追加時に使用する"
  value       = aws_lb_listener.listener_http.arn
}

output "listener_https_arn" {
  description = "HTTPS(443)リスナーのARN。リスナールール追加時に使用する"
  value       = aws_lb_listener.listener_https.arn
}
