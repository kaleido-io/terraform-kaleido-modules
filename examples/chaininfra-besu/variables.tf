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
  type = string
  sensitive = true
}

# ─── Besu network configuration ───────────────────────────────────────────────

variable "network_name" {
  type = string
  default = "besu"
  description = "Display name of the BesuNetwork (kaleido_platform_network, type `Besu`)."
}

variable "stack_name" {
  type = string
  default = "besu"
  description = "Display name of the chain-infrastructure stack that wraps the network. Besu nodes are created against this stack's ID."
}

variable "chain_id" {
  type = number
  description = "Network chain ID."
}
