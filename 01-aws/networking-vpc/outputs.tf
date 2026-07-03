output "public_ip" {
  value = aws_instance.free_tier_ec2.public_ip
}

output "instance_id" {
  value = aws_instance.free_tier_ec2.id
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}