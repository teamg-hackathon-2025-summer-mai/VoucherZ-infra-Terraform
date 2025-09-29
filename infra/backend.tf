terraform {
  backend "s3" {
    bucket = "${var.project_prefix}-tfstate-ap-northeast-1"
    key = "terraform.tfstate"
    region = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt = true
  }
}