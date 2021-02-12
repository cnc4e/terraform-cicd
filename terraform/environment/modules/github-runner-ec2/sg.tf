resource "aws_security_group" "github_runner" {
  name        = "${var.pj}-github-runner-sg"
  vpc_id      = var.vpc_id
  description = "For GitHub Runner EC2"

  tags = merge(
    {
      "Name" = "${var.pj}-github-runner-sg"
    },
    var.tags
  )

  # インバウンドは設定しない

  egress {
    description = "Allow any outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}