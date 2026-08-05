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
  description = "ID of a pre-existing environment. Leave empty to create a new environment named `environment_name`."
  default     = ""
}

variable "environment_name" {
  type        = string
  description = "Name for the environment to create. Only used when `environment_id` is empty."
  default     = "paladin"
}

# ─── Paladin network configuration ──────────────────────────────────────────────

variable "network_name" {
  type        = string
  description = "Name of the Paladin network."
  default     = "paladin-network"
}

variable "node_count" {
  type        = number
  description = "Number of Paladin nodes to create. Node 1 deploys the registry."
  default     = 3
  validation {
    condition     = var.node_count >= 1
    error_message = "node_count must be at least 1 (node 1 deploys the registry)."
  }
}

variable "node_name_prefix" {
  type        = string
  description = "Prefix for Paladin node names (`<prefix>-1` ... `<prefix>-N`)."
  default     = "paladin-node"
}

variable "paladin_ref" {
  type        = string
  description = "Git ref (branch name or commit SHA) of the Paladin repo to source the domain contracts from."
  default     = "5baa0c8e5f8b7b55e5055de9cef2a83b1b361dae"
}

variable "paladin_repo" {
  type        = string
  description = "GitHub repository URL to source the domain contracts from."
  default     = "https://github.com/LFDT-Paladin/paladin"
}

variable "domains" {
  type        = any
  description = "Additional Paladin domain config keyed by domain name, merged over the noto/pente domains this example deploys."
  default     = {}
}

variable "publish_hostnames" {
  type        = bool
  description = "Publish each node's jsonrpc/jsonrpcws endpoints on a hostname named after the node."
  default     = false
}

# ─── Base ledger + keys ─────────────────────────────────────────────────────────

variable "signing_key_address" {
  type        = string
  description = "Deploy signer for the domain factories as a 0x… address. Overrides the domain-deployer key this example creates."
  default     = null
  validation {
    condition     = var.signing_key_address == null || var.signing_key_uri == null
    error_message = "Set at most one of signing_key_address or signing_key_uri."
  }
}

variable "signing_key_uri" {
  type        = string
  description = "Deploy signer for the domain factories as a Key Manager key URI. Overrides the domain-deployer key this example creates."
  default     = null
}

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
