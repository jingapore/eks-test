resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-test-vpc"
  }
}

resource "aws_subnet" "sub_a_web" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1a"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 0)

  tags = {
    Name = "eks-test-sub-a-web"
    Tier = "Private"
  }
}

resource "aws_subnet" "sub_b_web" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 1)

  tags = {
    Name = "eks-test-sub-b-web"
    Tier = "Private"
  }
}

resource "aws_subnet" "sub_a_app" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1a"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 2)

  tags = {
    Name = "eks-test-sub-a-app"
    Tier = "Private"
  }
}

resource "aws_subnet" "sub_b_app" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 3)

  tags = {
    Name = "eks-test-sub-b-app"
    Tier = "Private"
  }
}

resource "aws_subnet" "sub_a_db" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1a"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 4)

  tags = {
    Name = "eks-test-sub-a-db"
    Tier = "Private"
  }
}

resource "aws_subnet" "sub_b_db" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 5)

  tags = {
    Name = "eks-test-sub-b-db"
    Tier = "Private"
  }
}

resource "aws_subnet" "sub_a_devops_cicd" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1a"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 6)

  tags = {
    Name = "eks-test-sub-a-devops-cicd"
    Tier = "Private"
  }
}

resource "aws_subnet" "sub_b_devops_cicd" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 7)

  tags = {
    Name = "eks-test-sub-b-devops-cicd"
    Tier = "Private"
  }
}

resource "aws_subnet" "sub_a_public" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1a"
  cidr_block        = cidrsubnet(var.subnet_public_range, 3, 0)
  tags = {
    Name = "eks-test-sub-a-public"
    Tier = "Public"
  }
}

resource "aws_subnet" "sub_b_public" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = cidrsubnet(var.subnet_public_range, 3, 1)
  tags = {
    Name = "eks-test-sub-b-public"
    Tier = "Public"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "public_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.sub_a_public.id
}

resource "aws_route_table_association" "public_b" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.sub_b_public.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}
