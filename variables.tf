
variable "access_key" {
  default = "access-key here"
}

variable "secret_key" {
  default = "secret-key here"
}

variable "region" {
    default = "ap-south-1"
}

variable "type" {
    default = "t2.micro"
}

variable "ami-id" {
    default = "ami-052cef05d01020f1d"
}

variable "project" {
  default = "prod"
  
}

variable "asg_count" {
  default =2
  
}

variable "vpc-id" {
  default = "vpc-0eb0bd9ac0ac8d0990967"
}

variable "cert-arn" {
  default = "Enter SSL cert-arn here"

  
}
