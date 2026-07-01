provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "first_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
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

resource "aws_instance" "free_tier_ec2" {
    ami = "ami-06067086cf86c58e6"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.first_subnet.id
}