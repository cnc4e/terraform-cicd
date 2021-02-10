terraform {
  required_version = ">= 0.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.13.0"
    }
  }

  backend "s3" {
    bucket         = "tf-cicd-tfstate-delivery"
    key            = "github-runner/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "tf-cicd-tfstate-lock-delivery"
    region         = "ap-southeast-2"
  }
}