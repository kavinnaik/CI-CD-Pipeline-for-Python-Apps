output "ssh_example" {
  value = "ssh -i <your-key.pem> ec2-user@${aws_instance.web.public_dns}"
}
