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

variable "terraform_iam_identifier" {
  type        = string
  default     = ""
  description = "identifier beginning with AIDA to lock access to s3 bucket"
}