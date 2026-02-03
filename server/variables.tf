variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "size" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "key_name" {
  description = "Key pair name"
  type        = string
  default     = "2026-01-30"
}