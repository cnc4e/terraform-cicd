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

resource "aws_instance" "deployed_instance" {
  ami                         = data.aws_ami.recent_amazon_linux_2.image_id
  instance_type               = var.ec2_instance_type
  associate_public_ip_address = true
  subnet_id                   = var.ec2_subnet_id
  vpc_security_group_ids      = [aws_security_group.deployed_instance.id]

  tags = merge(
    {
      "Name" = "${var.pj}-deployed-instance-${var.env}"
    },
    var.tags
  )

  root_block_device {
    volume_size = var.ec2_root_block_volume_size
  }

  key_name = var.ec2_key_name
}

