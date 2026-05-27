variable "environment_name" {
  type = string
}

variable "databases" {
  type = object({
    wfe_db           = string
    cms_db           = string
    kms_db           = string
    bis_db           = string
    ecs_db           = string
    ams_db           = string
    wms_db           = string
    pms_db           = string
  })
  default = null
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

# ─── EVM (Ethereum Sepolia) connector endpoint ────────────────────────────────

variable "evm_jsonrpc_url" {
  type        = string
  description = "JSON-RPC URL for the Ethereum Sepolia endpoint the EVM connector should target."
}

variable "evm_jsonrpc_auth" {
  type = object({
    username = string
    password = string
  })
  default     = null
  sensitive   = true
  description = "Optional basic-auth credentials for the EVM JSON-RPC endpoint."
}

variable "evm_network" {
  type = object({
    name        = string
    displayName = optional(string)
    chainId     = optional(string)
  })
  default = {
    name        = "ethereum-sepolia"
    displayName = "Ethereum Sepolia"
    chainId     = "11155111"
  }
  description = "Network metadata for the EVM connector."
}

variable "evm_ecosystem" {
  type = object({
    name        = string
    displayName = optional(string)
  })
  default = {
    name        = "ethereum"
    displayName = "Ethereum"
  }
  description = "Ecosystem metadata for the EVM connector."
}

variable "evm_confirmations" {
  type = object({
    count = optional(number, 0)
    resubmission = optional(object({
      enabled = optional(bool, false)
      timeout = optional(string, "5m")
    }))
  })
  default = {
    count = 6
    resubmission = {
      enabled = true
    }
  }
  description = "evm.confirmations profile passed to the EVM connector. Defaults match the Ethereum Sepolia 6-confirmation override."
}

# ─── BTC (Bitcoin Testnet3) connector endpoint ────────────────────────────────

variable "btc_rpc_url" {
  type        = string
  description = "Bitcoin Core RPC URL for the Bitcoin Testnet3 endpoint the BTC connector should target."
}

variable "btc_rpc_auth" {
  type = object({
    username = string
    password = string
  })
  default     = null
  sensitive   = true
  description = "Basic-auth credentials for the Bitcoin Core RPC endpoint."
}

variable "btc_network" {
  type = object({
    name        = string
    displayName = optional(string)
  })
  default = {
    name        = "bitcoin-testnet3"
    displayName = "Bitcoin Testnet3"
  }
  description = "Network metadata for the BTC connector."
}

variable "btc_fee_rate" {
  type = any
  default = {
    source = {
      fixedFeeRate = {
        enabled = true
        satVb   = 1
      }
    }
  }
  description = "btc.feeRate profile passed to the BTC connector. Defaults to a fixed 1 sat/vB rate suitable for Testnet3 application testing."
}

variable "btc_monitoring" {
  type = object({
    monitoringInterval    = optional(string)
    requiredConfirmations = optional(number)
    staleTimeout          = optional(string)
  })
  default = {
    requiredConfirmations = 1
    staleTimeout          = "5m"
    monitoringInterval    = "2s"
  }
  description = "btc.monitoring profile passed to the BTC connector. Defaults tuned for Testnet3 with 1 required confirmation."
}
