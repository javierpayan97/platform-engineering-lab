terraform {
  backend "s3" {
    bucket = "devops-test-tf-state-jepm-97"
    key = "02-terraform/web-app/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt = true
  }

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "6.54.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "instance_1" {
    ami = "ami-0b6d9d3d33ba97d99"
    instance_type = "t3.micro"
    security_groups = [aws_security_group.instances.name]
    user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World 1" > index.html
    python3 -m http.server 8080 &
    EOF
}

resource "aws_instance" "instance_2" {
    ami = "ami-0b6d9d3d33ba97d99"
    instance_type = "t3.micro"
    security_groups = [aws_security_group.instances.name]
    user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World 2" > index.html
    python3 -m http.server 8080 &
    EOF
}

resource "aws_s3_bucket" "bucket_data" {
    bucket = "devops-test-web-app-data-jepm-97"
    force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning" {
    bucket = aws_s3_bucket.bucket_data.id
    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.bucket_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

data "aws_vpc" "default_vpc" {
    default = true
}

data "aws_subnets" "default_subnet" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default_vpc.id]
    }
}

resource "aws_security_group" "instances" {
    name = "instance-security_groups"
}

resource "aws_security_group_rule" "allow_http_inbound" {
    security_group_id = aws_security_group.instances.id
    type = "ingress"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port = 80
  protocol = "HTTP"
  
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_target_group" "instances" {
    name = "example-target-group"
    port = 8080
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default_vpc.id

    health_check {
      path = "/"
      protocol = "HTTP"
      matcher = "200"
      interval = 15
      timeout = 2
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
}

resource "aws_lb_target_group_attachment" "instance_1" {
    target_group_arn = aws_lb_target_group.instances.arn
    target_id = aws_instance.instance_1.id
    port = 8080
}

resource "aws_lb_target_group_attachment" "instance_2" {
    target_group_arn = aws_lb_target_group.instances.arn
    target_id = aws_instance.instance_2.id
    port = 8080
}

resource "aws_lb_listener_rule" "name" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
      path_pattern {
        values = ["*"]
      }
    }
    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.instances.arn
    }
}

resource "aws_security_group" "alb" {
    name = "alb-security-group" 
}

resource "aws_security_group_rule" "allow_alb_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
    type = "egress"
    security_group_id = aws_security_group.alb.id
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "load_balancer" {
    name = "web-app-lb"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default_subnet.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_db_instance" "db_instance" {
    allocated_storage = 20
    storage_type = "standard"
    engine = "postgres"
    engine_version = "18.3"
    instance_class = "db.t4g.micro"
    db_name = "mydb"
    username = "foo"
    password = "foobarbaz"
    skip_final_snapshot = true
}