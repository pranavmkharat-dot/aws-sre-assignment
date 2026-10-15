
variable "aws_region" {
  description = "AWS region for the S3 bucket."
  type        = string
  default     = "ap-southeast-2"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"
}

