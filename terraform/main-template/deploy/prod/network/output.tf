output "vpc_id" {
  value = module.deployed_network.vpc_id
}

output "public_subnet_ids" {
  value = module.deployed_network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.deployed_network.private_subnet_ids
}