# ─── Platform auth ────────────────────────────────────────────────────────────

variable "kaleido_platform_api" {
  type        = string
  description = "Base URL of your Kaleido Platform API."
}

variable "kaleido_platform_username" {
  type        = string
  description = "Kaleido Platform API username."
}

variable "kaleido_platform_password" {
  type        = string
  sensitive   = true
  description = "Kaleido Platform API password."
}

# ─── Environment ──────────────────────────────────────────────────────────────

variable "environment_name" {
  type        = string
  default     = "evm-dynamic-gas"
  description = "Name of the environment to create."
}

# ─── Key Manager ──────────────────────────────────────────────────────────────

variable "key_manager_name" {
  type        = string
  default     = "keys"
  description = "Name of the KeyManager runtime and service."
}

# ─── EVM Connector ────────────────────────────────────────────────────────────

variable "jsonrpc_url" {
  type        = string
  description = "JSON-RPC endpoint URL of the EVM network (e.g. a public Sepolia RPC)."
}

variable "jsonrpc_auth" {
  type = object({
    username = string
    password = string
  })
  default     = null
  description = "Optional basic-auth credentials for the JSON-RPC endpoint."
  sensitive   = true
}
