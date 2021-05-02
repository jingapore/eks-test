variable "aws_profile" {
  type        = string
  default     = ""
  description = "aws profile to input into aws provider"
}

variable "subnet_private_range" {
  type        = string
  default     = "10.0.0.0/16"
  description = "range for private subnet"
}