terraform {
  backend "s3" {
    bucket = "ekstest-terraformstatebucket"
    key    = "2/eks-test-terraform-state.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = "ap-southeast-1"
}