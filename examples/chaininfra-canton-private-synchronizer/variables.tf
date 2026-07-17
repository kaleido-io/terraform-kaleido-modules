variable "environment_name" {
  type = string
  default = "canton-chain-infra"
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