# ─── Platform (provider auth + environment) ───────────────────────────────────

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

variable "environment_name" {
  type    = string
  default = "middleware-evm-prelondon"
}

# ─── Pre-London Besu chain ─────────────────────────────────────────────────────

variable "chain_id" {
  type        = number
  default     = 3333
  description = "Chain ID baked into the genesis. The connector signs legacy (EIP-155) transactions with this value — the firefly-signer fix under test ensures it is encoded correctly (no 'wrong chain ID' rejection)."
}

variable "initial_balance" {
  type        = string
  default     = "0x3635C9ADC5DEA00000" // 1000 ETH
  description = "Genesis pre-funded balance (hex wei) for the connector's deployer key."
}
