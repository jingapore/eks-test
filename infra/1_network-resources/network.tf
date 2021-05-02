resource "aws_vpc" "main" {
  cidr_block = var.subnet_private_range
  enable_dns_support = true
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
  }
}

resource "aws_subnet" "sub_b_web" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 1)

  tags = {
    Name = "eks-test-sub-b-web"
  }
}

resource "aws_subnet" "sub_a_app" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1a"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 2)

  tags = {
    Name = "eks-test-sub-a-app"
  }
}

resource "aws_subnet" "sub_b_app" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 3)

  tags = {
    Name = "eks-test-sub-b-app"
  }
}

resource "aws_subnet" "sub_a_db" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1a"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 4)

  tags = {
    Name = "eks-test-sub-a-db"
  }
}

resource "aws_subnet" "sub_b_db" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 5)

  tags = {
    Name = "eks-test-sub-b-db"
  }
}

resource "aws_subnet" "sub_a_devops_cicd" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1a"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 6)

  tags = {
    Name = "eks-test-sub-a-devops-cicd"
  }
}

resource "aws_subnet" "sub_b_devops_cicd" {

  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = cidrsubnet(var.subnet_private_range, 3, 7)

  tags = {
    Name = "eks-test-sub-b-devops-cicd"
  }
}