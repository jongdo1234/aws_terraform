output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "public_security_group_id" {
  description = "Public security group ID"
  value       = aws_security_group.public.id
}

output "private_security_group_id" {
  description = "Private security group ID"
  value       = aws_security_group.private.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "public_server_ip" {
  description = "Public server IP"
  value       = module.public_server.public_ip
}

output "private_server_ip" {
  description = "Private server IP"
  value       = module.private_server.private_ip
}