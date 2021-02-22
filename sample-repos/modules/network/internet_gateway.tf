resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      "Name" = "${var.pj}-internet-gateway"
    },
    var.tags
  )
}