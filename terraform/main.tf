terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 2
}

resource "aws_security_group" "web_sg" {
  name        = "ci-cd-python-aws-sg-${random_id.suffix.hex}"
  description = "Allow SSH and HTTP access"
  vpc_id      = data.aws_vpc.default.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ci-cd-python-aws-sg"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon Linux
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_instances" "existing" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-ec2"]
  }
}

locals {
  existing_instance_id = try(data.aws_instances.existing.ids[0], "")
}


resource "aws_instance" "web" {
  count = local.existing_instance_id == "" ? 1 : 0

  ami                         = data.aws_ami.linux.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")

  tags = {
    Name        = "${var.project_name}-ec2"
    Environment = "Development"
  }

  lifecycle {
    prevent_destroy = false
    create_before_destroy = false
  }
}

output "ec2_public_ip" {
  value       = length(aws_instance.web) > 0 ? aws_instance.web[0].public_ip : ""
  description = "Public IP of the EC2 instance"
}

output "ec2_public_dns" {
  value       = length(aws_instance.web) > 0 ? aws_instance.web[0].public_dns : ""
  description = "Public DNS of the EC2 instance"
}


