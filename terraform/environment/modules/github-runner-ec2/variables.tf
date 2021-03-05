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
variable "ec2_github_url" {
  description = "GitHub Runnerのアクセス先となる、GitHubのURL"
  type        = string
}

variable "ec2_registration_token" {
  description = "グループrunnerとして登録するためのトークン"
  type        = string
}

variable "ec2_runner_name" {
  description = "GitHubで表示されるrunnerの名前"
  type        = string
}

variable "ec2_runner_version" {
  description = "GitHub Runnerのバージョン"
  type        = string
}

variable "ec2_runner_tags" {
  description = "runnerに付与するタグのリスト"
  type        = list(string)
}

variable "ec2_instance_type" {
  description = "GitHub Runnerのインスタンスタイプ"
  type        = string
}

variable "ec2_subnet_id" {
  description = "GitHub Runnerを配置するパブリックサブネットのID"
  type        = string
}

variable "ec2_root_block_volume_size" {
  description = "GitHub Runnerのルートデバイスの容量(GB)"
  type        = string
}

variable "ec2_key_name" {
  description = "GitHub Runnerのインスタンスにsshログインするためのキーペア名"
  type        = string
}

variable "cloudwatch_enable_schedule" {
  description = "GitHubインスタンスを自動起動/停止するか"
  type        = bool
  default     = false
}

variable "cloudwatch_start_schedule" {
  description = "GitHubインスタンスを自動起動する時間。時間の指定はUTCのため注意"
  type        = string
  default     = "cron(0 0 ? * MON-FRI *)"
}

variable "cloudwatch_stop_schedule" {
  description = "GitHubインスタンスを自動停止する時間。時間の指定はUTCのため注意"
  type        = string
  default     = "cron(0 10 ? * MON-FRI *)"
}