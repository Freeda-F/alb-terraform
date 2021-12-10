#key-pair creation
resource "aws_key_pair" "key" {
  key_name   = "devkey"
  public_key = file ("devkey.pub")
}

#security-group creation
resource "aws_security_group" "demo" {
  name        = "demo"
  description = "Allow all inbound traffic"

  ingress {
    description      = ""
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "demo-sg"
  }
}

#security-group for Web Application
resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Allow 80,443,22 inbound traffic"

  ingress = [
    {
    description      = ""
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
    self = false
  },
  {
    description      = ""
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
     self = false
  },
  {
        description      = ""
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
     self = false
  }
  ]



  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# get details of VPC and its subnets

data "aws_subnet_ids" "vpc" {
  vpc_id = var.vpc-id
}