
variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "name" {
  type    = string
  default = "sre-web"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}
