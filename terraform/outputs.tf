output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.web.public_ip
}

output "proxmox_vm_ip" {
  description = "IP address of Proxmox VM"
  value       = var.proxmox_vm_ip
}

output "alb_dns" {
  description = "DNS name of ALB"
  value       = aws_lb.alb.dns_name
}