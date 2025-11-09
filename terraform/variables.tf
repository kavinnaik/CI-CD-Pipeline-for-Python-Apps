variable "project_name" { default = "ci-cd-python-aws" }
variable "aws_region"   { type = string }
variable "instance_type" { default = "t2.micro" }
variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for EC2"
  type        = string
  default     = "ci-cd-key"
}
variable "allow_ssh_cidr" { default = "0.0.0.0/0" } # replace with your IP/CIDR for security
