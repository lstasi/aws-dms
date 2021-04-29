terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
terraform {
  backend "local" {
    path = ".tfstate/terraform.tfstate"
  }
}
# Configure the AWS Provider
provider "aws" {
  region = var.region
}
data "aws_caller_identity" "current" {}

output "lb-dns" {
  value = aws_lb.dms-lb.dns_name
}