variable "environment_name" {
  type        = string
  default     = "besu-chain-infra"
  description = "Name of the environment to create."
}

variable "kaleido_platform_api" {
  type = string
}

variable "kaleido_platform_username" {
  type = string
}

variable "kaleido_platform_password" {
  type      = string
  sensitive = true
}
