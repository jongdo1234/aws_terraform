variable "aws_region" {
  default = "ap-northeast-2"
}

variable "project_name" {
  default = "WorldPay"
}

# VPC
variable "vpc_a_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_b_cidr" {
  default = "10.1.0.0/16"
}

# Subnets
variable "public_subnet_1_cidr" {
  default = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  default = "10.0.3.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "data_subnet_1_cidr" {
  default = "10.1.1.0/24"
}

variable "data_subnet_2_cidr" {
  default = "10.1.2.0/24"
}

variable "az_1" {
  default = "ap-northeast-2a"
}

variable "az_2" {
  default = "ap-northeast-2c"
}

# EC2
variable "instance_type" {
  default = "t3.micro"
}

variable "ami_name_pattern" {
  default = "al2023-ami-2023*-x86_64"
}

# RDS
variable "db_name" {
  default = "worldpay"
}

variable "db_username" {
  default = "admin"
}

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "db_engine_version" {
  default = "8.0"
}

variable "db_allocated_storage" {
  default = 20
}

variable "db_multi_az" {
  default = true
}

# ALB
variable "alb_internal" {
  default = false
}

variable "health_check_path" {
  default = "/"
}

# CloudWatch
variable "log_retention_days" {
  default = 7
}
