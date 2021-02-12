locals {
  default_init_script = <<SHELLSCRIPT
#!/bin/bash

# Download runner
mkdir actions-runner && cd actions-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.273.4/actions-runner-linux-x64-2.273.4.tar.gz
tar xzf ./actions-runner-linux-x64-2.273.4.tar.gz

# setup runner
chmod 777 -R /actions-runner
su - ec2-user -c '/actions-runner/config.sh --url ${var.ec2_github_url} --token ${var.ec2_registration_token} --name ${var.ec2_runner_name} --work _work --labels ${join(",", var.ec2_runner_tags)}'
su - ec2-user -c '/actions-runner/run.sh'
/actions-runner/svc.sh install
/actions-runner/svc.sh start
    SHELLSCRIPT
}

data "aws_ami" "recent_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "github_runner" {
  ami                         = data.aws_ami.recent_amazon_linux_2.image_id
  instance_type               = var.ec2_instance_type
  iam_instance_profile        = aws_iam_instance_profile.github_runner.name
  associate_public_ip_address = true
  subnet_id                   = var.ec2_subnet_id
  vpc_security_group_ids      = [aws_security_group.github_runner.id]
  user_data                   = local.default_init_script

  tags = merge(
    {
      "Name" = "${var.pj}-github-runner"
    },
    var.tags
  )

  root_block_device {
    volume_size = var.ec2_root_block_volume_size
  }

  key_name = var.ec2_key_name
}

