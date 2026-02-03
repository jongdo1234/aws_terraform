output "public_ip" {
  description = "Public IP address"
  value       = aws_instance.web_server.public_ip
}

output "public_dns" {
  description = "Public DNS name"
  value       = aws_instance.web_server.public_dns
}

output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.web_server.id
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.web_server.private_ip
}