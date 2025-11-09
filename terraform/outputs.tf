output "ssh_example" {
  value = length(aws_instance.web) > 0 ? "ssh -i <your-key.pem> ec2-user@${aws_instance.web[0].public_dns}" : "No EC2 instance created"
}

