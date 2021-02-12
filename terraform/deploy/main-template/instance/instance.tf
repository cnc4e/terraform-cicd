terraform {
  required_version = ">= 0.13.2"
}

provider "aws" {
  version = ">= 3.5.0"
  region  = "REGION"
}

# import network value
data "terraform_remote_state" "deployed_network" {
  backend = "s3"

  config = {
    bucket         = "PJ-NAME-tfstate-dev"
    key            = "network/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "PJ-NAME-tfstate-lock-dev"
    region         = "REGION"
  }
}

# parameter settings
locals {
  pj     = "PJ-NAME"
  vpc_id = data.terraform_remote_state.deployed_network.outputs.vpc_id
  tags = {
    pj     = "PJ-NAME"
    owner = "OWNER"
  }

  ec2_subnet_id              = data.terraform_remote_state.deployed_network.outputs.private_subnet_ids[0]
  ec2_instance_type          = "t2.micro"
  ec2_root_block_volume_size = 10
  ec2_key_name               = ""
  
  sg_ingress_port         = [0]
  sg_ingress_cidr            = "210.148.59.64/28"
}

module "deployed_instance" {
  source = "../../../modules/instance"

  # common parameter
  pj     = local.pj
  vpc_id = local.vpc_id
  tags   = local.tags

  # module parameter
  ec2_subnet_id              = local.ec2_subnet_id
  ec2_instance_type          = local.ec2_instance_type
  ec2_root_block_volume_size = local.ec2_root_block_volume_size
  ec2_key_name               = local.ec2_key_name
  
  sg_ingress_port            = local.sg_ingress_port
  sg_ingress_cidr            = local.sg_ingress_cidr
}
