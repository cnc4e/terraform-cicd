resource "aws_nat_gateway" "ngw" {
  count = length(var.subnet_public_cidrs)

  allocation_id = aws_eip.natgw[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      "Name" = "${var.pj}-nat-gateway-${count.index}"
    },
    var.tags
  )
}