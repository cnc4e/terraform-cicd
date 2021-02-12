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
variable "env_names" {
    description = "バックエンドを配置する環境"
    type        = list(string)
}