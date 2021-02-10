terraform {
  required_version = ">= 0.13.2"
}

provider "aws" {
  version = ">= 3.5.0"
  region  = "ap-southeast-2"
}

# import network value
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket         = "tf-cicd-tfstate-delivery"
    key            = "network/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "tf-cicd-tfstate-lock-delivery"
    region         = "ap-southeast-2"
  }
}

# parameter settings
locals {
  pj     = "tf-cicd"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  tags = {
    pj     = "tf-cicd"
    owner = "nobody"
  }

  ec2_github_url             = "https://github.com/nariryo/tf-cicd"
  ec2_registration_token     = "AKSL7XAY3FV3PO7KKL7ZBXDAENHU4"
  ec2_runner_name            = ""
  ec2_runner_tags            = ""
  ec2_subnet_id              = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  ec2_instance_type          = "t2.micro"
  ec2_root_block_volume_size = 30
  ec2_key_name               = ""

  ## 自動スケジュール
  cloudwatch_enable_schedule = false
  cloudwatch_start_schedule  = "cron(0 0 ? * MON-FRI *)"
  cloudwatch_stop_schedule   = "cron(0 10 ? * MON-FRI *)"
}

module "github-runner" {
  source = "../../../modules/environment/github-runner-ec2"

  # common parameter
  pj     = local.pj
  vpc_id = local.vpc_id
  tags   = local.tags

  # module parameter
  ec2_github_url             = local.ec2_github_url
  ec2_registration_token     = local.ec2_registration_token
  ec2_runner_name            = "${local.pj}-runner"
  ec2_runner_tags            = [local.pj]
  ec2_subnet_id              = local.ec2_subnet_id
  ec2_instance_type          = local.ec2_instance_type
  ec2_root_block_volume_size = local.ec2_root_block_volume_size
  ec2_key_name               = local.ec2_key_name

  cloudwatch_enable_schedule = local.cloudwatch_enable_schedule
  cloudwatch_start_schedule  = local.cloudwatch_start_schedule
  cloudwatch_stop_schedule   = local.cloudwatch_stop_schedule
}
