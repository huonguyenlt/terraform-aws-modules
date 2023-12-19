variable "azs" {
  description = "The number of availability zones to use"
  default = 2
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  default = "10.0.0.0/16"
}

variable "name" {
  description = "The name of the VPC"
  default = "my-vpc"
}