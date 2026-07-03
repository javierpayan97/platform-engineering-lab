provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "Javier VPC"
    }
}

resource "aws_subnet" "first_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "my_rt" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
}

resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.first_subnet.id
    route_table_id = aws_route_table.my_rt.id
}

resource "aws_security_group" "ec2_sg" {
    name = "ec2-sg"
    vpc_id = aws_vpc.main_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["89.116.40.184/32"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "free_tier_ec2" {
    ami = "ami-06067086cf86c58e6"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.first_subnet.id
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}