# Amazon Linux 2023 최신 AMI 조회
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }
}

# 서비스 EC2 인스턴스
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = aws_subnet.vpc_a_public_1.id

  tags = { Name = "${var.project_name}-App-Server" }
}

# KMS Key 생성
resource "aws_kms_key" "wp_key" {
  description         = "KMS Key for ${var.project_name}"
  enable_key_rotation = true
  tags                = { Name = "${var.project_name}-KMS" }
}

# Secrets Manager
resource "aws_secretsmanager_secret" "db_secret" {
  name       = "${var.project_name}-DB-Credentials"
  kms_key_id = aws_kms_key.wp_key.arn
}
