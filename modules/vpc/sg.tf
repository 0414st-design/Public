# 1. ALB/Web用 SG (外部からのHTTP/HTTPSを許可)
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

  # アウトバウンド: 全許可（外部へのパッチ取得などのため）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-web-sg" })
}

# 2. App層用 SG (Web SGからの通信のみを許可)
resource "aws_security_group" "app" {
  name        = "${var.vpc_name}-app-sg"
  description = "Allow traffic from Web SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 8080 # アプリのポート例
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id] # SG IDで指定するのがミソ
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-app-sg" })
}

# 3. DB層用 SG (App SGからのDB通信のみを許可)
resource "aws_security_group" "db" {
  name        = "${var.vpc_name}-db-sg"
  description = "Allow traffic from App SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 5432 # PostgreSQLの例。MySQLなら3306
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-db-sg" })
}