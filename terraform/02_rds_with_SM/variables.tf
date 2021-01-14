variable "public_subnet" {
  default = ["10.100.0.0/24", "10.100.2.0/24", "10.100.4.0/24"]
  type = list
}

variable "private_subnet" {
  default = ["10.100.1.0/24", "10.100.3.0/24", "10.100.5.0/24"]
  type = list
}

variable "vpc_cidr" {
  default = "10.100.0.0/16"
}

variable "availability_zones" {
  description = "AZs in this region to use"
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  type = list
}

variable "public_name" {
  default = ["public_10.100.0.0_a", "public_10.100.2.0_b", "public_10.100.4.0_c"]
  type = list
}

variable "private_name" {
  default = ["private_10.100.1.0_a", "private_10.100.3.0_b", "private_10.100.5.0_c"]
  type = list
}

variable "public_cidr" {
  default = "0.0.0.0/0"
}