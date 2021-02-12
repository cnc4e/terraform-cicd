# common parameter
variable "tags" {
  description = "リソース群に付与する共通タグ"
  type        = map(string)
}

variable "pj" {
  description = "リソース群に付与する接頭語"
  type        = string
}

variable "vpc_id" {
  description = "リソース群が属するVPCのID"
  type        = string
}

# module parameter
variable "ec2_instance_type" {
  description = "デプロイインスタンスのインスタンスタイプ"
  type        = string
}

variable "ec2_subnet_id" {
  description = "デプロイインスタンスを配置するプライベートサブネットのID"
  type        = string
}

variable "ec2_root_block_volume_size" {
  description = "デプロイインスタンスのルートデバイスの容量(GB)"
  type        = string
}

variable "ec2_key_name" {
  description = "デプロイインスタンスにsshログインするためのキーペア名"
  type        = string
}

variable "sg_ingress_port" {
  description = "デプロイインスタンスのセキュリティグループのインバウンド終端ポート"
  type        = list(string)
}

variable "sg_ingress_cidr" {
  description = "デプロイインスタンスのセキュリティグループのインバウンドCIDR"
  type        = string
}