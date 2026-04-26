# セキュリティグループ（SG）
# インスタンス単位で適用するステートフルなファイアウォール。
# ステートフルのため、インバウンドを許可すればレスポンスは自動的に返せる。
# CIDRではなくSG IDで参照することで、IPが変わっても自動追従する。

# --------------------------------------------------------------------------------------------------
# 1. Web層 SG
# インターネットからのHTTP/HTTPSを受け付ける（ALB用）
# --------------------------------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "${var.vpc_name}-web-sg"
  description = "Allow HTTP/HTTPS from Internet"
  vpc_id      = aws_vpc.this.id

  # インバウンド: HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # インバウンド: HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンド: 全許可（app層へのルーティングやAWSサービスへの通信）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-web-sg" })
}

# --------------------------------------------------------------------------------------------------
# 2. App層 SG
# Web SGからの通信のみを許可
# --------------------------------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${var.vpc_name}-app-sg"
  description = "Allow traffic from Web SG"
  vpc_id      = aws_vpc.this.id

  # インバウンド: Web SGからのアプリポートのみ
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # アウトバウンド: 全許可（NAT GW経由でのパッケージ取得・AWSサービスへの通信）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-app-sg" })
}

# --------------------------------------------------------------------------------------------------
# 3. DB層 SG
# App SGからのDB通信のみを許可
# EgressはVPC内CIDRに限定（ルートテーブルも閉域のため、インターネットへの経路なし）
# --------------------------------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "${var.vpc_name}-db-sg"
  description = "Allow traffic from App SG"
  vpc_id      = aws_vpc.this.id

  # インバウンド: App SGからのDBポートのみ（PostgreSQL: 5432 / MySQL: 3306）
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # アウトバウンド: VPC内CIDRのみ（appへのレスポンス返却のみ許可）
  # ルートテーブルで閉域化済みだが、SGでも明示的に制限することで多層防御を実現
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-db-sg" })
}

# --------------------------------------------------------------------------------------------------
# 4. Management層 SG
# 踏み台・監視・CI/CDランナー用
# management_subnet_offsets = [] の場合でもSGは作成しておく（EC2等から参照できるように）
# --------------------------------------------------------------------------------------------------
resource "aws_security_group" "management" {
  name        = "${var.vpc_name}-management-sg"
  description = "Allow SSH from trusted sources and monitoring traffic"
  vpc_id      = aws_vpc.this.id

  # インバウンド: VPC内からのSSHのみ（踏み台経由のアクセス）
  # 本番では特定のIPに絞ることを推奨
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # アウトバウンド: 全許可（パッケージ取得・監視エージェントの通信）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-management-sg" })
}