variable "environment_id" {
  type        = string
  description = "ID of the environment to deploy the Paladin node into."
}

variable "network_id" {
  type        = string
  description = "paladin-node-service-config.network.id — ID of the Paladin network to join (chaininfra-paladin-network network_id output)."
}

variable "stack_id" {
  type        = string
  description = "ID of the chain-infrastructure stack the runtime and service belong to (chaininfra-paladin-network stack_id output)."
}

variable "node_name" {
  type        = string
  description = "Name of the Paladin node runtime and service. On the registry-admin node (deploy mode) this must equal the network's registry_admin.node_name."
}

variable "runtime_size" {
  type        = string
  default     = "Small"
  description = "PaladinNodeRuntime size (ExtraSmall | Small | Medium | Large | ExtraLarge)."
  validation {
    condition     = contains(["ExtraSmall", "Small", "Medium", "Large", "ExtraLarge"], var.runtime_size)
    error_message = "runtime_size must be one of: ExtraSmall, Small, Medium, Large, ExtraLarge."
  }
}

variable "runtime_zone" {
  type        = string
  default     = null
  description = "Availability/deployment zone for the runtime. Null uses the platform default."
}

variable "storage_size" {
  type        = number
  default     = null
  description = "Runtime storage size in GB. Null uses the platform default."
}

variable "storage_type" {
  type        = string
  default     = null
  description = "Runtime storage type. Null uses the platform default."
}

variable "key_manager_service_id" {
  type        = string
  description = "paladin-node-service-config.keyManager.id — ID of the KeyManagerService holding the node's signing keys."
}

variable "base_ledger" {
  type = object({
    type                 = string
    gateway_service_id   = optional(string)
    besu_node_service_id = optional(string)
    jsonrpc_url          = optional(string)
    ws_url               = optional(string)
    auth = optional(object({
      username = string
      password = string
    }))
  })
  sensitive   = true
  description = "paladin-node-service-config.baseLedgerEndpoint — how the node reaches the base EVM ledger. type = local: exactly one of gateway_service_id (EVMGatewayService, preferred) or besu_node_service_id (BesuNodeService). type = endpoint: jsonrpc_url and ws_url, with optional basic-auth credentials (delivered via a cred set)."
  validation {
    condition     = contains(["local", "endpoint"], var.base_ledger.type)
    error_message = "base_ledger.type must be one of: local, endpoint."
  }
  validation {
    condition = var.base_ledger.type != "local" || (
      (var.base_ledger.gateway_service_id != null) != (var.base_ledger.besu_node_service_id != null)
    )
    error_message = "base_ledger.type = local requires exactly one of gateway_service_id or besu_node_service_id."
  }
  validation {
    condition = var.base_ledger.type != "endpoint" || (
      var.base_ledger.jsonrpc_url != null && var.base_ledger.ws_url != null
    )
    error_message = "base_ledger.type = endpoint requires both jsonrpc_url and ws_url."
  }
}

variable "registry_admin_identity" {
  type        = string
  description = "paladin-node-service-config.registryAdminIdentity — identity used to administer registry entries for this node. Required on every node; must match the network's registry_admin.identity in deploy mode."
}

variable "wallets" {
  type = object({
    kms_key_store      = string
    kms_folder_path    = optional(string)
    zeto_wallet_prefix = optional(string)
    zeto_wallet_seed   = optional(string)
  })
  sensitive   = true
  description = "paladin-node-service-config.wallets — kms_key_store names the KMS keystore/wallet backing the node's keys; kms_folder_path scopes keys to a folder. The zeto_* fields are a temporary workaround while zeto keys live outside KMS (seed delivered via a cred set) and are subject to change."
}

variable "domains" {
  type        = any
  default     = {}
  description = "baseConfig.domains — Paladin domain plugin config keyed by domain name (e.g. noto/pente/zeto), including each domain's factory registryAddress. `any`-typed by design: the schema is owned by the Paladin project (pldconf)."
}

variable "base_config" {
  type        = any
  default     = {}
  description = "Extra baseConfig entries (blockIndexer, sequencerManager, publicTxManager, ...). `any`-typed by design: pldconf.PaladinConfig is a large open schema owned by the Paladin project. db, log, blockchain, rpcServer, transports, registries, keyManager, and debugServer are platform-managed and overwritten by the operator if set here."
}

variable "hostname" {
  type        = string
  default     = null
  description = "Optional hostname to publish the node's jsonrpc/jsonrpcws endpoints on. Null skips hostname creation."
}

variable "read_registry_address" {
  type        = bool
  default     = false
  description = "Set true on the registry-admin node (deploy mode) to read back the deployed EVM registry address once the node is up. Leave false on other nodes and in existing mode."
}
