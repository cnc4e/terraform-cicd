resource "aws_security_group" "deployed_instance" {
  name        = "${var.pj}-deployed-instance-sg"
  vpc_id      = var.vpc_id
  description = "For Deployed EC2"

  tags = merge(
    {
      "Name" = "${var.pj}-deployed-instance-sg-${var.env}"
    },
    var.tags
  )
}

resource "aws_security_group_rule" "ingress" {
  count             = length(var.sg_ingress_port)
  type              = "ingress"
  from_port         = var.sg_ingress_port[count.index]
  to_port           = var.sg_ingress_port[count.index]
  protocol          = "tcp"
  cidr_blocks       = [var.sg_ingress_cidr]
  security_group_id = aws_security_group.deployed_instance.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.deployed_instance.id
}