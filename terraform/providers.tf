terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.45"
    }
  }

  cloud {
    organization = "htg-org-name"
    workspaces {
      name = "project-automation-production"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true   # ← FIX SSL self-signed cert
}

