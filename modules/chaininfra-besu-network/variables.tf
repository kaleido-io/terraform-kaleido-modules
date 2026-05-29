variable "environment_id" {
  type        = string
  description = "ID of the environment to deploy the Besu network and chain-infrastructure stack into."
}

variable "network_name" {
  type        = string
  default     = "besu"
  description = "Display name of the BesuNetwork (kaleido_platform_network, type `Besu`)."
}

variable "stack_name" {
  type        = string
  default     = "besu"
  description = "Display name of the chain-infrastructure stack that wraps the network. Besu nodes are created against this stack's ID."
}

# ─── Initialization ───────────────────────────────────────────────────────────

variable "init_mode" {
  type        = string
  default     = "automated"
  description = "Network initialization mode. `automated` (default) bootstraps a genesis from `bootstrapOptions`; `manual` expects an externally-supplied genesis. Forced to `manual` when `genesis_json` is set."
  validation {
    condition     = contains(["automated", "manual"], var.init_mode)
    error_message = "init_mode must be one of: automated, manual."
  }
}

variable "genesis_json" {
  type        = string
  default     = null
  description = "Inline genesis.json content as a string. When set, the network is initialized in `manual` mode with this file supplied as the `init` file set (`genesis.json`, type `json`), letting callers render the genesis in HCL (e.g. `jsonencode(...)`) and own/upgrade it over time. Leave null to let the platform bootstrap a genesis from `bootstrapOptions`."
}

# ─── besu-network-config (bootstrapOptions) ─────────────────────────────────────
# Strongly-typed mirror of the BesuNetworkConfig / BesuBootstrapConfig schema.
# Ignored when `genesis_json` is supplied.

variable "chain_id" {
  type        = number
  default     = null
  description = "besu-network-config.chainID — network chain ID. Generated automatically when null in `automated` init mode."
}

variable "qbft" {
  type = object({
    blockperiodseconds    = optional(number, 5)
    epochlength           = optional(number)
    requesttimeoutseconds = optional(number)
    blockreward           = optional(string)
    miningbeneficiary     = optional(string)
  })
  default     = { blockperiodseconds = 5 }
  description = "bootstrapOptions.qbft — QBFT consensus configuration (block period, epoch length, request timeout, block reward, mining beneficiary)."
}

variable "eip_block_config" {
  type        = map(number)
  default     = { shanghaiTime = 0, osakaTime = 0 }
  description = "bootstrapOptions.eipBlockConfig — EIP fork activation block/timestamps for the genesis config. Defaults activate both Shanghai and Osaka at genesis."
}

variable "block_config_flags" {
  type        = map(bool)
  default     = { zeroBaseFee = true }
  description = "bootstrapOptions.blockConfigFlags — boolean flags injected into the genesis config (e.g. `zeroBaseFee`)."
}

variable "initial_validators" {
  type        = list(string)
  default     = []
  description = "bootstrapOptions.initialValidators — validator addresses to seed into the genesis block. Omitted from config when empty."
}

variable "initial_balances" {
  type        = map(string)
  default     = {}
  description = "bootstrapOptions.initialBalances — map of address to balance (e.g. `0x...` hex wei) to pre-fund in the genesis block. Omitted from config when empty."
}

variable "target_gas_limit" {
  type        = number
  default     = null
  description = "bootstrapOptions.targetGasLimit — maximum gas spendable by all transactions in a block. Omitted (platform default) when null."
}
