# DB Subnet Group
resource "aws_db_subnet_group" "wp_db_subnet" {
  name       = lower("${var.project_name}-db-subnet-group")
  subnet_ids = [aws_subnet.vpc_b_data_1.id, aws_subnet.vpc_b_data_2.id]
  tags       = { Name = "${var.project_name}-DB-SubnetGroup" }
}

# RDS MySQL 인스턴스
resource "aws_db_instance" "mysql" {
  allocated_storage      = var.db_allocated_storage
  engine                 = "mysql"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_password.result
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.wp_db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.wp_key.arn
  multi_az               = var.db_multi_az

  tags = { Name = "${var.project_name}-RDS" }
}

# 랜덤 비밀번호 생성
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Secrets Manager에 DB 자격증명 저장
resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "wp_logs" {
  name              = "/${lower(var.project_name)}/app-logs"
  retention_in_days = var.log_retention_days
}

# ALB
resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-ALB"
  internal           = var.alb_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.vpc_a_public_1.id, aws_subnet.vpc_a_public_2.id]

  tags = { Name = "${var.project_name}-ALB" }
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_a.id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = { Name = "${var.project_name}-TG" }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server.id
  port             = 80
}

# ALB Listener (HTTP 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
