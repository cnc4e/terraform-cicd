provider "aws" {
  region  = "REGION"
}

# parameter settings
locals {
  pj       = "PJ-NAME"
  env      = "production"
  vpc_cidr = "10.3.0.0/16"
  vpc_id   = module.deployed_network.vpc_id
  tags = {
    pj    = "PJ-NAME"
    owner = "OWNER"
    env   = "production"
  }

  subnet_public_cidrs  = ["10.3.10.0/24", "10.3.11.0/24"]
  subnet_private_cidrs = ["10.3.20.0/24", "10.3.21.0/24"]

  ec2_subnet_id              = module.deployed_network.private_subnet_ids[0]
  ec2_instance_type          = "t2.large"
  ec2_root_block_volume_size = 30
  ec2_key_name               = ""

  sg_ingress_port = [22, 80, 443]
  sg_ingress_cidr = "210.148.59.64/28"
}

module "deployed_network" {
  source = "../../modules/network"

  # common parameter
  pj   = local.pj
  tags = local.tags

  # module parameter
  vpc_cidr = local.vpc_cidr

  subnet_public_cidrs  = local.subnet_public_cidrs
  subnet_private_cidrs = local.subnet_private_cidrs
}

module "deployed_instance" {
  source = "../../modules/instance"

  # common parameter
  pj     = local.pj
  vpc_id = local.vpc_id
  tags   = local.tags

  # module parameter
  ec2_subnet_id              = local.ec2_subnet_id
  ec2_instance_type          = local.ec2_instance_type
  ec2_root_block_volume_size = local.ec2_root_block_volume_size
  ec2_key_name               = local.ec2_key_name

  sg_ingress_port = local.sg_ingress_port
  sg_ingress_cidr = local.sg_ingress_cidr
}