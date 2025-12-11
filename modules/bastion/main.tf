# Get latest Ubuntu 24.04 LTS Minimal AMI (ARM64 for t4g instances)
# Ubuntu Minimal is lightweight and ideal for bastion hosts
data "aws_ami" "ubuntu_minimal" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-minimal-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# Security Group for Bastion
resource "aws_security_group" "bastion" {
  name        = "${var.project}-${var.environment}-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed CIDR blocks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-bastion-sg"
    Environment = var.environment
    Project     = var.project
  })
}

# User data script using cloud-init for reliability
locals {
  ssh_keys_list = [for username, key in var.ssh_public_keys : key]

  user_data = <<-EOF
#cloud-config
package_update: true
packages:
  - postgresql-client

users:
  - default
  - name: ubuntu
    ssh_authorized_keys:
%{for key in local.ssh_keys_list~}
      - ${key}
%{endfor~}
  EOF
}

# Bastion EC2 Instance (Spot)
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu_minimal.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  user_data = local.user_data

  # Spot instance configuration
  dynamic "instance_market_options" {
    for_each = var.use_spot_instance ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        spot_instance_type = "one-time"
      }
    }
  }

  # Root volume
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-bastion"
    Environment = var.environment
    Project     = var.project
  })

  lifecycle {
    ignore_changes = [ami]
  }
}
