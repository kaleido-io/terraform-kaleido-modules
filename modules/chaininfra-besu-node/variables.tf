variable "environment_id" {
  type        = string
  description = "ID of the environment to deploy the Besu node into."
}

variable "stack_id" {
  type        = string
  description = "ID of the chain-infrastructure (BesuStack) the node belongs to — e.g. the `stack_id` output of the chaininfra-besu-network module."
}

variable "network_id" {
  type        = string
  description = "ID of the BesuNetwork the node joins (besu-node-service-config.network.id) — e.g. the `network_id` output of the chaininfra-besu-network module."
}

variable "node_name" {
  type        = string
  default     = "besu-node"
  description = "Display name of the BesuNode runtime and service."
}

# ─── Runtime placement & sizing ─────────────────────────────────────────────────
# Default to null to inherit the platform's defaults.

variable "runtime_size" {
  type        = string
  default     = null
  description = "BesuNodeRuntime size (ExtraSmall | Small | Medium | Large | ExtraLarge). Null uses the platform default."
}

variable "zone" {
  type        = string
  default     = null
  description = "Availability/deployment zone for the runtime. Null uses the platform default."
}

variable "subzone" {
  type        = string
  default     = null
  description = "Subzone for the runtime. Null lets the underlying scheduler choose the best subzone for the runtime within the zone."
}

variable "storage_type" {
  type        = string
  default     = null
  description = "Storage class/type for the runtime's persistent volume. Null uses the platform default."
}

variable "storage_size" {
  type        = number
  default     = null
  description = "Persistent volume size in GB for the runtime. Null uses the platform default."
}

# ─── besu-node-service-config ───────────────────────────────────────────────────
# Strongly-typed mirror of the BesuNodeServiceConfig schema. Defaults codify
# Kaleido best practices for an archive RPC node.

variable "signer" {
  type        = bool
  default     = false
  description = "besu-node-service-config.signer — whether the node is added as a signer/validator to the network. Defaults to false (non-signing node)."
}

variable "routable" {
  type        = bool
  default     = true
  description = "besu-node-service-config.routable — whether the node is eligible for inclusion as a backend in a gateway."
}

variable "sync_mode" {
  type        = string
  default     = "FULL"
  description = "besu-node-service-config.syncMode — blockchain sync mode. Defaults to FULL (archive)."
  validation {
    condition     = contains(["FULL", "SNAP"], var.sync_mode)
    error_message = "sync_mode must be one of: FAST, FULL, SNAP."
  }
}

variable "log_level" {
  type        = string
  default     = "INFO"
  description = "besu-node-service-config.logLevel — desired log level of the Besu runtime."
  validation {
    condition     = contains(["INFO", "DEBUG", "TRACE", "ERROR", "WARN"], var.log_level)
    error_message = "log_level must be one of: INFO, DEBUG, TRACE, ERROR, WARN."
  }
}

variable "data_storage_format" {
  type        = string
  default     = "BONSAI"
  description = "besu-node-service-config.dataStorageFormat — database storage format. Defaults to BONSAI."
  validation {
    condition     = contains(["FOREST", "BONSAI"], var.data_storage_format)
    error_message = "data_storage_format must be one of: FOREST, BONSAI."
  }
}

variable "apis_enabled" {
  type        = list(string)
  default     = ["TRACE"]
  description = "besu-node-service-config.apisEnabled — additional Besu API methods to enable. ETH, QBFT/IBFT, ADMIN, NET, DEBUG, TXPOOL and WEB3 are always enabled. Defaults to [TRACE]."
  validation {
    condition     = alltrue([for a in var.apis_enabled : contains(["DEBUG", "MINER", "PERM", "PLUGINS", "TRACE", "TXPOOL", "WEB3"], a)])
    error_message = "apis_enabled entries must be among: DEBUG, MINER, PERM, PLUGINS, TRACE, TXPOOL, WEB3."
  }
}

variable "custom_besu_args" {
  type        = list(string)
  default     = ["--revert-reason-enabled"]
  description = "besu-node-service-config.customBesuArgs — additional arguments appended to the Besu command line. Defaults to [--revert-reason-enabled]."
}

variable "target_gas_limit" {
  type        = number
  default     = null
  description = "besu-node-service-config.targetGasLimit — maximum gas spendable in a transaction. Omitted (platform default) when null."
}

variable "gas_price" {
  type        = string
  default     = "0"
  description = "besu-node-service-config.gasPrice — gas price for transactions."
}

variable "genesis_json" {
  type        = string
  default     = null
  description = "Inline genesis.json content for this node, supplied as the `genesis` file set (type `json`). Typically only needed when joining a network whose genesis you manage externally. Null lets the node use the network's bootstrapped genesis."
}

variable "node_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "secp256k1 private key for the node identity (omit the leading `0x`). When set, registered as a `nodeKey` cred set and referenced from the service config. Generated by the platform when null."
}
