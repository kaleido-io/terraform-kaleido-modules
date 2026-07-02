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
  default = 12345
  description = "Network chain ID."
}

# --- Gas configuration ───────────────────────────────────────────────

variable "fund_holder_balance" {
  type = string
  default = "0x111111111111"
  description = "Balance of the fund holder in wei."
}

# ─── Validator Configuration ───────────────────────────────────────────────

variable "validator_count" {
  type = number
  default = 1
  description = "Number of validator nodes to deploy."
}

variable "rpc_node_count" {
  type = number
  default = 1
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