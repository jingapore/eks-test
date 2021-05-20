variable "aws_profile" {
  type        = string
  default     = ""
  description = "aws profile to input into aws provider"
}

variable "create_s3_vpce" {
  type = bool
  description = "whether or not to create s3 vpc endpoint"
}

variable "eks_public_access_cidrs" {
  type        = list(string)
  description = "cidr blocks to access eks, i.e. make kubectl commands"
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "vpc id"
}