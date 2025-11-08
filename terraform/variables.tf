variable "project_name" { default = "ci-cd-python-aws" }
variable "aws_region"   { type = string }
variable "instance_type" { default = "t3.micro" }
variable "ssh_key_name"  { description = "Existing AWS key pair name" }
variable "allow_ssh_cidr" { default = "0.0.0.0/0" } # replace with your IP/CIDR for security
