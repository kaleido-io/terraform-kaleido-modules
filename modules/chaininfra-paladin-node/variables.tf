variable "environment_id" {
  type        = string
  description = "ID of the Kaleido environment to deploy the Paladin node into."
}

variable "network_id" {
  type        = string
  description = "ID of the Paladin network to join."
}

variable "stack_id" {
  type        = string
  description = "ID of the chain-infrastructure stack the runtime and service belong to"
}

variable "node_name" {
  type        = string
  description = "Name of the Paladin node runtime and service. On the registry node (deploy mode) this must equal the network's registry_node."
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
  description = "Availability/deployment zone for the runtime. Uses the platform default if not specified."
}

variable "storage_size" {
  type        = number
  default     = null
  description = "Runtime storage size in GB. Uses the platform default if not specified."
}

variable "storage_type" {
  type        = string
  default     = null
  description = "Runtime storage type. Uses the platform default if not specified."
}

variable "key_manager_service_id" {
  type        = string
  description = "ID of the KeyManagerService holding the node's signing keys."
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
  description = "connectivity information for the base ledger"
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

variable "wallets" {
  type = object({
    kms_key_store      = string
    kms_folder_path    = optional(string)
    zeto_wallet_prefix = optional(string)
    zeto_wallet_seed   = optional(string)
  })
  sensitive   = true
  description = "kms_key_store names the KMS keystore/wallet backing the node's keys; kms_folder_path scopes keys to a folder. The zeto_* fields are a temporary workaround while zeto keys live outside KMS (seed delivered via a cred set) and are subject to change."
}

variable "domains" {
  type        = any
  default     = {}
  description = "Paladin domain plugin config keyed by domain name (e.g. noto/pente/zeto), including each domain's factory registryAddress. `any`-typed by design: the schema is owned by the Paladin project (pldconf)."
}

variable "base_config" {
  type        = any
  default     = {}
  description = "Extra paladin configuration. See the Paladin project for configuration options."
}

variable "hostname" {
  type        = string
  default     = null
  description = "Optional hostname to publish the node's jsonrpc/jsonrpcws endpoints on. If omitted, will use the platform default hostname."
}

variable "network_registry" {
  type = object({
    mode          = string
    registry_node = optional(string)
  })
  default     = null
  description = "The network's EVM registry configuration. When this node is the registry node in deploy mode, the module reads back the deployed registry address and exposes it as the registry_address output."
  validation {
    condition     = var.network_registry == null || contains(["deploy", "existing"], var.network_registry.mode)
    error_message = "network_registry.mode must be one of: deploy, existing."
  }
  validation {
    condition     = var.network_registry == null || var.network_registry.mode != "deploy" || var.network_registry.registry_node != null
    error_message = "network_registry.registry_node is required when network_registry.mode = deploy."
  }
}
