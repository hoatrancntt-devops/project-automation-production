variable "aws_region" {
  default = "ap-southeast-1"
}

variable "ami_id" {
  default = "ami-0672fd5b9210aa093"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 + Proxmox VM"
  type        = string
  sensitive   = true
}

variable "proxmox_api_url" {
  default = "https://172.199.10.165:8006/api2/json"
}

variable "proxmox_password" {
  description = "Proxmox root password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  default = "proxmox02"
}

variable "proxmox_vm_id" {
  default = 1100
}

variable "proxmox_vm_ip" {
  description = "IP address for Proxmox VM"
  default     = "172.199.10.180"
}

variable "proxmox_vm_cidr" {
  description = "CIDR notation for Proxmox VM network"
  default     = "24"
}

variable "proxmox_vm_gateway" {
  description = "Gateway for Proxmox VM"
  default     = "172.199.10.1"
}

variable "vm_template" {
  default = "rocky-cloud-init"
}
variable "proxmox_api_token" {
  description = "Proxmox API token (terraform@pam!tf-token=UUID)"
  type        = string
  sensitive   = true
}

variable "proxmox_ssh_password" {
  description = "Proxmox SSH password for cloud-init upload"
  type        = string
  sensitive   = true
}

variable "AWS_ACCESS_KEY_ID" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}
variable "proxmox_node" {
  default = "proxmox02"   # tên node Proxmox thực tế
}

