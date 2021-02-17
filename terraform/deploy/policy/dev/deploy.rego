package terraform
 
import input as tfplan
 
# Parameters
ec2_instance_type = "t2.micro"
ec2_root_block_volume_size = 10
sg_ingress_port = [0]
sg_ingress_cidr = "210.148.59.64/28"
subnet_count = 1
natgw_count = 1

# 配列対要素の比較
array_contains(arr, elem) {
  arr[_] = elem
}
 
# ec2_instance_type
violation_ec2_instance_type[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_instance"
    not r.change.after.instance_type == ec2_instance_type

    reason := sprintf(
      "%-40s :: instance type %q is not allowed",
      [r.address, r.change.after.instance_type]
    )
}

# ec2_root_block_volume_size
deny[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_instance"
    root_block_device = r.change.after.root_block_device[_]
    not root_block_device.volume_size == ec2_root_block_volume_size

    reason := sprintf(
      "%-40s :: instance volume %d is exceeded",
      [r.address, root_block_device.volume_size]
    )
}

# sg_ingress_port
deny[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_security_group_rule"
    r.name == "ingress"
    not array_contains(sg_ingress_port, r.change.after.from_port)
    not array_contains(sg_ingress_port, r.change.after.to_port)

    reason := sprintf(
      "%-40s :: ingress port '%d' is not allowed",
      [r.address, r.change.after.from_port]
    )
}

# sg_ingress_cidr
deny[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_security_group_rule"
    r.name == "ingress"
    not array_contains(r.change.after.cidr_blocks, sg_ingress_cidr)

    reason := sprintf(
      "%-40s :: ingress cidr '%s' is not allowed",
      [r.address, r.change.after.cidr_blocks]
    )
}

# is_redundant_natgw
deny[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_nat_gateway"
    not count(r) == natgw_count

    reason := sprintf(
      "%-40s :: %d natgw is not expected",
      [r.address, count(r)]
    )
}

# is_redundant_subnet
deny[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_subnet"
    r.name == "private"
    not count(r) == subnet_count

    reason := sprintf(
      "%-40s :: %d %s subnet is not expected",
      [r.address, count(r), r.name]
    )
}

# is_redundant_subnet
deny[reason] {
    r := tfplan.resource_changes[_]
    r.mode == "managed"
    r.type == "aws_subnet"
    r.name == "public"
    not count(r) == subnet_count

    reason := sprintf(
      "%-40s :: %d %s subnet is not expected",
      [r.address, count(r), r.name]
    )
}