terraform {
  required_version = ">= 0.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.13.0"
    }
  }

  backend "s3" {
    bucket         = "PJ-NAME-tfstate-dev"
    key            = "deploy/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "PJ-NAME-tfstate-lock-dev"
    region         = "REGION"
  }
}