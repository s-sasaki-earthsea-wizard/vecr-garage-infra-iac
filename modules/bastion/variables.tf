variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Bastion will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for Bastion"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.nano"
}

variable "use_spot_instance" {
  description = "Whether to use spot instance"
  type        = bool
  default     = true
}

variable "ssh_public_keys" {
  description = "Map of username to SSH public key"
  type        = map(string)
  default     = {}
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to Bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
