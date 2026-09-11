variable "environment_name" {
  type = string
  default = "canton-chain-infra"
}

# ─── Account 1 configuration ───────────────────────────────────────────────
variable "kaleido_platform_api_account_1" {
  type = string
}

variable "kaleido_platform_username_account_1" {
  type = string
}

variable "kaleido_platform_password_account_1" {  
  type = string
}

# ─── Account 2 configuration ───────────────────────────────────────────────
variable "kaleido_platform_api_account_2" {
  type = string
}

variable "kaleido_platform_username_account_2" {
  type = string
}

variable "kaleido_platform_password_account_2" {  
  type = string
}

# ─── Canton synchronizer network configuration ───────────────────────────────────────────────

variable "synchronizer_network_name" {
  type = string
  default = "canton-synchronizer"
}

# -- Key Manager Service configuration ───────────────────────────────────────────────
variable "kms_wallet_type" {
  type = string
  default = "kaleidokeystore"
}

variable "kms_key_spec" {
  type = string
  default = "secp256r1"
}

# ─── Network connector configuration ───────────────────────────────────────────────

variable "platform_connector_zone" {
  type = string
}