variable "aws_region" {
  type    = string
  default = "ap-south-1"
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
  default = 2
}
variable "desired_capacity" {
  type    = number
  default = 2
}
variable "max_size" {
  type    = number
  default = 4
}
