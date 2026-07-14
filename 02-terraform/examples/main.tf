provider "aws" {
    region = "us-east-1"
}

locals {
  extra_tag = "extra-tag"
}
#ubuntu instance
resource "aws_instance" "free_tier_ec2" {
    ami = "ami-0b6d9d3d33ba97d99"
    instance_type = "t3.micro"
}

terraform {
    backend "s3" {
        bucket = "devops-test-tf-state-jepm-97"
        key = "tf-infra/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-state-locking"
        encrypt = true
    }
}