# common parameter
variable "tags" {
  description = "リソース群に付与する共通タグ"
  type        = map(string)
}

variable "pj" {
  description = "リソース群に付与する接頭語"
  type        = string
}

# module parameter
variable "vpc_cidr" {
  description = "VPCのネットワークアドレス帯"
  type        = string
}

variable "subnet_public_cidrs" {
  description = "パブリックサブネットのアドレス帯"
  type        = list(string)
}
