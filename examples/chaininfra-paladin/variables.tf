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

variable "environment_id" {
  type        = string
  description = "ID of a pre-existing environment to create the network in. Leave empty to create a new environment named `environment_name`."
  default     = ""
}

variable "environment_name" {
  type        = string
  description = "Name for the environment to create. Only used when `environment_id` is empty."
  default     = ""
}

# ─── Paladin network configuration ──────────────────────────────────────────────

variable "network_name" {
  type        = string
  description = "Name of the Paladin network."
  default     = "paladin-network"
}

variable "node_count" {
  type        = number
  description = "Number of Paladin nodes to create. Node 1 is the registry admin."
  default     = 2
}

variable "node_name_prefix" {
  type        = string
  description = "Prefix for Paladin node names (`<prefix>-1` ... `<prefix>-N`). Node 1 is the registry admin."
  default     = "paladin-node"
}

variable "registry_admin_identity" {
  type        = string
  description = "Identity that deploys and administers the EVM registry."
  default     = "registry.admin"
}

variable "domains" {
  type        = any
  description = "Optional Paladin domain plugin config keyed by domain name (noto/pente/zeto), passed through to every node's baseConfig.domains."
  default     = {}
}

variable "publish_hostnames" {
  type        = bool
  description = "Publish each node's jsonrpc/jsonrpcws endpoints on a hostname named after the node."
  default     = false
}

# ─── Base ledger + keys ─────────────────────────────────────────────────────────

variable "besu_network_name" {
  type        = string
  description = "Name of the Besu network that serves as the base ledger."
  default     = "paladin-base"
}

variable "paladin_wallet_name" {
  type        = string
  description = "Name of the KMS hdwallet backing the Paladin nodes' keys."
  default     = "paladin-wallet"
}
