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

variable "genesis_json" {
  type = string
  default = null
  description = "Genesis JSON for the network."
}

# ─── Validator Configuration ───────────────────────────────────────────────

variable "validator_count" {
  type = number
  description = "Number of validator nodes to deploy."
}

variable "validator_node_keys" {
  type = list(string)
  description = "List of validator node keys."
  default = []
}

variable "rpc_node_count" {
  type = number
  description = "Number of RPC nodes to deploy."
}

# ─── Blockchain Application Firewall Configuration ───────────────────────────────────────────────

variable "baf_enabled" {
  type = bool
  description = "Whether to enable the Blockchain Application Firewall."
  default = false
}

variable "baf_policies" {
  type = list(object({
    file = string
    application_id = string
  }))
  description = "List of policies to deploy the Blockchain Application Firewall into. At least one of file or rego must be provided."
  default = []
}