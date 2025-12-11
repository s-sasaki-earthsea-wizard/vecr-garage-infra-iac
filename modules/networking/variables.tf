variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["ap-northeast-1a"]
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints for S3 and Secrets Manager"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region for VPC endpoints"
  type        = string
  default     = "ap-northeast-1"
}