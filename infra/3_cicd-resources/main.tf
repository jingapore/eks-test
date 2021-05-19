terraform {
  backend "s3" {
    bucket = "ekstest-terraformstatebucket"
    key    = "3/eks-test-terraform-state.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = "ap-southeast-1"
}

data "aws_eks_cluster" "default" {
  name = var.eks_cluster_name
}


data "aws_eks_cluster_auth" "default" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
    command     = "aws"
  }
}