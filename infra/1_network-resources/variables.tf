variable "aws_profile" {
  type        = string
  default     = ""
  description = "aws profile to input into aws provider"
}

variable "subnet_private_range" {
  type        = string
  description = "range for private subnet"
}

variable "subnet_public_range" {
  type        = string
  description = "range for private subnet"
}