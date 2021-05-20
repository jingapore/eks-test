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
  type        = string
  description = "name of eks cluster"
}


variable "vpc_id" {
  type        = string
  default     = ""
  description = "vpc id"
}

variable "backend_commit_id" {
  type = string
  default = ""
  description = <<-EOF
  commit id for backend that will be used for image tag in deployment, 
  but will not be needed after backend deployment has been initialised
  EOF
}