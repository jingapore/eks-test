variable "aws_profile" {
  type        = string
  default     = ""
  description = "aws profile to input into aws provider"
}

variable "aws_account_id" {
  type = string
  default = ""
  description = "aws account id to input into codebuild for pushing to ecr"
}

variable "backend_balancer_ip" {
  type = string
}

variable "backend_variables_mock_variable_1" {
  type    = string
  default = ""
}

variable "eks_cluster_name" {
  type = string
  default = ""
  description = "name of eks cluster, where cluster is created in previous module"
}

variable "terraform_iam_identifier" {
  type = string
  default = ""
  description = "iam identifier to be added to do-not-deny policy for s3 bucket"
}