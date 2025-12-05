output "instance_id" {
  description = "ID of the Bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "instance_arn" {
  description = "ARN of the Bastion EC2 instance"
  value       = aws_instance.bastion.arn
}

output "public_ip" {
  description = "Public IP of the Bastion instance"
  value       = aws_instance.bastion.public_ip
}

output "public_dns" {
  description = "Public DNS of the Bastion instance"
  value       = aws_instance.bastion.public_dns
}

output "security_group_id" {
  description = "ID of the Bastion security group"
  value       = aws_security_group.bastion.id
}

output "ssh_connection_command" {
  description = "SSH command to connect to Bastion"
  value       = "ssh ec2-user@${aws_instance.bastion.public_ip}"
}
