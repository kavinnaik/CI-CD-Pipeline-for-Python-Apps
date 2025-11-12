output "ssh_example" {
  value = try("ssh -i <your-key.pem> ec2-user@${aws_instance.web.public_dns}", "No EC2 instance created")
}

