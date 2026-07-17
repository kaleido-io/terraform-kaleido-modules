variable "environment_id" {
  type        = string
  description = "ID of the environment to deploy the Besu node into."
}

variable "stack_id" {
  type        = string
  description = "ID of the chain-infrastructure (BesuStack) the node belongs to — e.g. the `stack_id` output of the chaininfra-besu-network module."
}

variable "block_indexer_name" {
  type        = string
  default     = "block-indexer"
  description = "Display name of the BlockIndexer runtime and service."
}

# ─── Service-level config ─────────────────────────────────────────────────────

variable "contract_manager_service_id" {
  type        = string
  default     = ""
  description = "ID of the ContractManager service to connect to the BlockIndexer."
}

variable "evm_gateway_service_id" {
  type        = string
  description = "ID of the EVMGateway service to connect to the BlockIndexer."
}

variable "hostname" {
  type        = string
  default     = "block-indexer"
  description = "Hostname of the BlockIndexer."
}
# ─── Runtime placement & sizing ─────────────────────────────────────────────────
# Default to null to inherit the platform's defaults.

variable "blockindexer_size" {
  type        = string
  default     = null
  description = "BlockIndexerRuntime size (ExtraSmall | Small | Medium | Large | ExtraLarge). Null uses the platform default."
}
