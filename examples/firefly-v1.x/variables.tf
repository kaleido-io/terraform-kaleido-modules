# ─── Platform (environment + provider auth) ───────────────────────────────────

variable "environment_name" {
  type = string
}

variable "kaleido_platform_api" {
  type = string
}

variable "kaleido_platform_password" {
  type      = string
  sensitive = true
}

variable "kaleido_platform_username" {
  type = string
}

variable "databases" {
  type = object({
    kms_db = string
    cms_db = string
    ams_db = string
    bis_db = string
  })
  default     = null
  description = "Optional external database names per service. Required only on platform instances configured for externally-provisioned databases; omit (null) for managed-database instances."
}

# ─── Shared services (cross-stack) ──────────────────────────────────────────────

variable "contract_manager_name" {
  type        = string
  description = "Name for the Contract Manager service"
  default     = "contracts"
}

variable "key_manager_name" {
  type        = string
  description = "Name for the Key Manager service"
  default     = "keys"
}

# ─── Chain infrastructure stack (Besu network + node + EVM gateway) ─────────────

variable "besu_network_name" {
  type        = string
  description = "Name for the Besu network"
  default     = "besu"
}

variable "besu_node_name" {
  type        = string
  description = "Name for the Besu Node service"
  default     = "besu-node-1"
}

variable "besu_stack_name" {
  type        = string
  description = "Name for the Besu stack"
  default     = "besu"
}

variable "evm_gateway_name" {
  type        = string
  description = "Name for the EVM Gateway service"
  default     = "besu-gateway-1"
}

variable "block_indexer_hostname" {
  type        = string
  description = "Hostname for the Block Indexer service"
}

variable "block_indexer_name" {
  type        = string
  description = "Name for the Block Indexer service"
  default     = "block-indexer-1"
}

# ─── Web3 middleware stack (FireFly + transaction manager) ──────────────────────

variable "firefly_name" {
  type        = string
  description = "Name for the Firefly service"
  default     = "firefly-1"
}

variable "transaction_manager_name" {
  type        = string
  description = "Name for the Transaction Manager service"
  default     = "evmchain-1-txmgr"
}

variable "web3_middleware_stack_name" {
  type        = string
  description = "Name for the Web3 Middleware stack"
  default     = "Web3-middleware"
}

# ─── Digital Assets stack (tokenization) ────────────────────────────────────────

variable "asset_manager_name" {
  type        = string
  description = "Name for the Asset Manager service"
  default     = "asset-manager-1"
}

variable "tokenization_stack_name" {
  type        = string
  description = "Name for the Digital Assets stack with Tokenization type"
  default     = "tokenization"
}
