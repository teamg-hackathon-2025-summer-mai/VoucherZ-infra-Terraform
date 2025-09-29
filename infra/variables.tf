variable "project_prefix" {
  type = string
  description = "Prefix used for resource names"
}

variable "vpc_cidr" {
  type = string
  description = "CIDR block for VPC"
}

variable "public_subnets" {
  description = "Public subnets map"
  type = map(object({
    az = string
    cidr = string
  }))
}

variable "private_subnets" {
  description = "Private subnets map"
  type = map(object({
    az = string
    cidr = string
    role = string
  }))
}

variable "rds_db_name" {
  default = "voucherz"
}

variable "web_image_tag" {
  type = string
}

variable "app_image_tag" {
  type = string
}