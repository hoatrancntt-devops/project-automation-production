terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.45"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure = true  # ← THÊM DÒNG NÀY để skip SSL verify
}

provider "aws" {
  region = var.aws_region
}
