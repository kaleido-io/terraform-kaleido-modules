variable "environment_name" {
  type = string
}

variable "kaleido_platform_api" {
  type = string
}

variable "kaleido_platform_username" {
  type = string
}

variable "kaleido_platform_password" {  
  type = string
}

# ─── Canton validator network configuration ───────────────────────────────────────────────
variable "validator_network_enabled" {
  type = bool
  default = true
  description = "To create the CantonValidatorNetwork."
}

variable "network_type" {
  type = string
  description = "Value of the network type to use for the CantonValidatorNetwork. Must be one of: Sandbox, Devnet, Testnet, Mainnet."
}

variable "sponsor_super_validator" {
  type = string
  default = "null"
  description = "Name of the sponsor super validator to use for the CantonValidatorNetwork. If not provided, the network will be created without a sponsor super validator."
}

variable "onboarding_secret_file" {
  type = string
  default = null
  description = "Path to the onboarding secret file. If not provided, the node will be created without an onboarding secret."
}

# ─── Canton synchronizer network configuration ───────────────────────────────────────────────
variable "synchronizer_network_enabled" {
  type = bool
  default = false
}

variable "synchronizer_network_name" {
  type = string
}

variable "kms_wallet_type" {
  type = string
  default = "hdwallet"
}