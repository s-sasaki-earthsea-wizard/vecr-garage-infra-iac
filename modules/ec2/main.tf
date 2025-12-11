# Data source to get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project}-${var.environment}-ec2-sg"
  description = "Security group for ${var.project} EC2 instances"
  vpc_id      = var.vpc_id

  # SSH access from anywhere (you might want to restrict this in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks
    description = "SSH access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project}-${var.environment}-ec2-sg"
    Environment = var.environment
    Project     = var.project
  }
}

# EC2 instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.iam_instance_profile_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "Setting up ${var.project} application server for ${var.environment} environment"
    
    # Update system and apply all updates
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    
    # Install required packages
    apt-get install -y \
    build-essential \
    awscli \
    jq \
    git \
    make \
    curl

    # Install Docker and Docker Compose
    
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker packages
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add ubuntu user to docker group
    sudo usermod -aG docker ubuntu
    
    # Add created users to docker group
    %{for user in var.users~}
    sudo usermod -aG docker ${user.username}
    %{endfor~}
    
    # Ensure ubuntu user's home directory exists
    mkdir -p /home/ubuntu
    chown ubuntu:ubuntu /home/ubuntu
    
    # Configure AWS CLI for root
    mkdir -p /root/.aws
    echo -e "[default]\nregion = ap-northeast-1" > /root/.aws/config
    chmod 600 /root/.aws/config
    
    # Configure AWS CLI for ubuntu user
    mkdir -p /home/ubuntu/.aws
    echo -e "[default]\nregion = ap-northeast-1" > /home/ubuntu/.aws/config
    chmod 600 /home/ubuntu/.aws/config
    chown -R ubuntu:ubuntu /home/ubuntu/.aws
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Create users and set up SSH keys
    %{for user in var.users~}
    # Create user ${user.username}
    useradd -m -s /bin/bash ${user.username}
    mkdir -p /home/${user.username}/.ssh
    chmod 700 /home/${user.username}/.ssh
    
    # Add user's SSH keys
    %{for key in user.ssh_keys~}
    echo "${key}" >> /home/${user.username}/.ssh/authorized_keys
    %{endfor~}
    chmod 600 /home/${user.username}/.ssh/authorized_keys
    chown -R ${user.username}:${user.username} /home/${user.username}/.ssh
    
    # Add user to sudoers
    echo "${user.username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${user.username}
    chmod 440 /etc/sudoers.d/${user.username}
    
    # Configure AWS CLI for user
    mkdir -p /home/${user.username}/.aws
    echo -e "[default]\nregion = ap-northeast-1" > /home/${user.username}/.aws/config
    chmod 600 /home/${user.username}/.aws/config
    chown -R ${user.username}:${user.username} /home/${user.username}/.aws
    %{endfor~}
    
    # Setup application directory
    mkdir -p /opt/${var.project}
    
    # Add more setup steps as needed
  EOF

  tags = {
    Name        = "${var.project}-${var.environment}-app-server"
    Environment = var.environment
    Project     = var.project
  }

  monitoring = var.detailed_monitoring_enabled

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for the EC2 instance (optional)
resource "aws_eip" "app_server" {
  count    = var.create_elastic_ip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.app_server.id

  tags = {
    Name        = "${var.project}-${var.environment}-app-server-eip"
    Environment = var.environment
    Project     = var.project
  }
}

# Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = var.create_elastic_ip ? aws_eip.app_server[0].public_ip : aws_instance.app_server.public_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2_sg.id
}