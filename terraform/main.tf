# ============ AWS ============
resource "aws_key_pair" "deployer" {
  key_name   = "project-automation-key"
  public_key = var.ssh_public_key
}

resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "project-automation-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "project-automation-public" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = { Name = "project-automation-public-b" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "project-automation-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id
  name   = "project-automation-web-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "project-automation-web-sg" }
}

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name
  tags                   = { Name = "project-automation-web" }
}

# ============ ALB ============
resource "aws_lb" "alb" {
  name               = "project-automation-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "project-automation-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 5000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ============ PROXMOX ============
# Upload cloud-init file to Proxmox datastore via SSH
resource "null_resource" "cloud_init_upload" {
  connection {
    type     = "ssh"
    host     = var.proxmox_host_ip
    user     = "root"
    password = var.proxmox_ssh_password
  }

  provisioner "file" {
    content = templatefile("${path.module}/cloud-init-basic.cfg", {
      ssh_public_key = var.ssh_public_key
    })
    destination = "/var/lib/vz/snippets/project-automation-ci.yml"
  }
}

# Note: VM cloning is handled by Ansible playbook after Terraform apply
# This bypasses the SSL certificate issue with bpg/proxmox provider
# See: ansible/proxmox_vm.yml

output "cloud_init_file" {
  value       = "Uploaded to: /var/lib/vz/snippets/project-automation-ci.yml"
  description = "Cloud-init file location on Proxmox host"
}

#output "proxmox_vm_ip" {
#  value       = var.proxmox_vm_ip
#  description = "Target IP for Proxmox VM (configure after VM creation)"
#:x}
