terraform {
  required_version = ">= 0.13.2"
}

provider "aws" {
  version = ">= 3.5.0"
  region  = "REGION"
}

# parameter settings
locals {
  pj   = "PJ-NAME"
  tags = {
    pj     = "PJ-NAME"
    owner = "OWNER"
  }
  
  env_names = ["delivery", "dev", "production"]
}

module "tf-backend" {
  source = "../../modules/tf-backend"
  
  pj  = local.pj
  tags = local.tags
  
  env_names = local.env_names
}
