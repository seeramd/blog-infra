terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for public HTTP/HTTPS traffic"
}

resource "aws_vpc_security_group_ingress_rule" "web_ports_ipv4" {
  for_each = {
    http  = 80
    https = 443
  }

  security_group_id = aws_security_group.web.id

  from_port   = each.value
  to_port     = each.value
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
  description = "${each.key}-inbound-ipv4"
}

resource "aws_vpc_security_group_ingress_rule" "web_ports_ipv6" {
  for_each = {
    http  = 80
    https = 443
  }

  security_group_id = aws_security_group.web.id

  from_port   = each.value
  to_port     = each.value
  ip_protocol = "tcp"
  cidr_ipv6   = "::0/0"
  description = "${each.key}-inbound-ipv6"
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.web.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "allow-all-outbound-ipv4"
  }
}

resource "aws_vpc_security_group_egress_rule" "all_ipv6" {
  security_group_id = aws_security_group.web.id

  ip_protocol = "-1"
  cidr_ipv6   = "::0/0"

  tags = {
    Name = "allow-all-outbound-ipv6"
  }
}

resource "aws_instance" "webserver" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  associate_public_ip_address = true

  tags = {
    Name = "websrv"
  }
}
