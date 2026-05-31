# ---------------------------------------------------------------------------
# locals: モジュール内で共通使用するタグをまとめる
# 呼び出し側から渡される var.tags をマージし、全リソースへ一括適用する
# ---------------------------------------------------------------------------
locals {
  common_tags = var.tags
}

# ---------------------------------------------------------------------------
# Security Group: ALB専用SG
# インターネットからのHTTP(80)/HTTPS(443)インバウンドのみ許可する
# アウトバウンドはEC2のSG参照に限定し、最小権限を適用する
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.alb_name}-sg"
  description = "Security group for ${var.alb_name}. Allows HTTP/HTTPS from the internet."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.alb_name}-sg"
  })
}

# HTTP(80) インバウンドルール: リダイレクト用に解放する
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from the internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(local.common_tags, {
    Name = "${var.alb_name}-ingress-http"
  })
}

# HTTPS(443) インバウンドルール: SSL終端用に解放する
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from the internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(local.common_tags, {
    Name = "${var.alb_name}-ingress-https"
  })
}

# アウトバウンドルール: EC2のSGのみを宛先とし、余分な通信を遮断する
resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow outbound to app instances only"
  from_port                    = var.target_port
  to_port                      = var.target_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.app_sg_id

  tags = merge(local.common_tags, {
    Name = "${var.alb_name}-egress-to-app"
  })
}

# ---------------------------------------------------------------------------
# Security Group Rule: EC2側SGへのインバウンド許可
# ALBのSGをソースとして参照し、EC2がALBからの通信のみ受け付けるよう制限する
# このルールはEC2側SGを直接変更するため、影響範囲を明示するコメントを残す
# ---------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = var.app_sg_id
  description                  = "Allow inbound from ALB on target port"
  from_port                    = var.target_port
  to_port                      = var.target_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = merge(local.common_tags, {
    Name = "${var.alb_name}-app-ingress-from-alb"
  })
}

# ---------------------------------------------------------------------------
# Target Group: EC2（target_port）へHTTP転送するターゲットグループ
# ALBでSSL終端を行い、バックエンドへはHTTPで転送する構成とする
# ---------------------------------------------------------------------------
resource "aws_lb_target_group" "tg" {
  name                 = "${var.alb_name}-tg"
  port                 = var.target_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    matcher             = "200-299"
  }

  tags = merge(local.common_tags, {
    Name = "${var.alb_name}-tg"
  })

  # ALBを先に削除してからターゲットグループを削除する順序を保証する
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Application Load Balancer: インターネット向けALB本体
# 複数AZのパブリックサブネットに配置し、可用性を確保する
# ---------------------------------------------------------------------------
resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  idle_timeout       = var.idle_timeout

  # 削除保護: 本番環境での誤削除を防ぐために有効化する
  enable_deletion_protection = true

  # クロスゾーン負荷分散: 複数AZ間でリクエストを均等分散する
  enable_cross_zone_load_balancing = true

  # HTTPヘッダー落とし: 無効なヘッダーフィールドを持つリクエストを拒否する
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = var.alb_name
  })
}

# ---------------------------------------------------------------------------
# Listener (HTTP:80): HTTPSへのリダイレクトのみを行う
# バックエンドへの直接転送は行わず、301リダイレクトで強制的にHTTPSへ誘導する
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.alb_name}-listener-http"
  })
}

# ---------------------------------------------------------------------------
# Listener (HTTPS:443): ACM証明書を使ってSSL終端を行い、ターゲットグループへ転送する
# SSLポリシーはTLS1.2以上を強制する推奨ポリシーをデフォルトとする
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.alb_name}-listener-https"
  })
}
