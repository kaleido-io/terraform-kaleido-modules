variable "environment_id" {
  type        = string
  description = "ID of the environment to deploy the Paladin connector into. A WorkflowEngine service must already exist in this environment — the platform auto-binds it to the connector."
}

variable "stack_name" {
  type        = string
  default     = "paladin-connector"
  description = "Name of the PaladinConnectorStack."
}

variable "connector_name" {
  type        = string
  default     = "paladin-connector"
  description = "Name of the PaladinConnector runtime and service."
}

variable "runtime_size" {
  type        = string
  default     = "Small"
  description = "PaladinConnector runtime size (ExtraSmall | Small | Medium | Large | ExtraLarge)."
  validation {
    condition     = contains(["ExtraSmall", "Small", "Medium", "Large", "ExtraLarge"], var.runtime_size)
    error_message = "runtime_size must be one of: ExtraSmall, Small, Medium, Large, ExtraLarge."
  }
}

variable "runtime_zone" {
  type        = string
  default     = null
  description = "Zone of the PaladinConnector runtime. Null uses the platform default."
}

variable "key_manager_service_id" {
  type        = string
  nullable    = false
  description = "ID of the KeyManager service to bind to the connector (config.keyManager.id)."
}

variable "paladin_node_service_id" {
  type        = string
  nullable    = false
  description = "ID of the PaladinNode service in the same environment to bind the connector to (config.paladinNode.id) — the `service_id` output of chaininfra-paladin-node."
}

variable "ecosystem" {
  type = object({
    name        = string
    displayName = optional(string)
  })
  default = {
    name        = "paladin"
    displayName = "Paladin"
  }
  nullable    = false
  description = "Ecosystem metadata block (config.ecosystem). The name must stay `paladin` to match the connector-manager ecosystem definition that carries the connector's default config profiles."
}

variable "network" {
  type = object({
    name        = string
    displayName = optional(string)
    chainId     = optional(string)
  })
  default     = null
  description = "Optional network metadata block (config.network), e.g. { name = \"paladin-network\" }."
}

variable "monitoring" {
  type = object({
    monitoringInterval = optional(string, "5s")
  })
  default     = {}
  nullable    = false
  description = "paladin.monitoring — how often the submission, pgroupCreate and pgroupSubmission flows poll the node for a transaction receipt."
}

variable "transaction_events" {
  type = object({
    pollTimeout = optional(string, "1s")
    batchSize   = optional(number, 1)
    unfiltered  = optional(bool, true)
    filters = optional(object({
      type   = optional(string)
      domain = optional(string)
    }))
    options = optional(object({
      domainReceipts                 = optional(bool)
      incompleteStateReceiptBehavior = optional(string)
    }))
  })
  default     = {}
  nullable    = false
  description = "paladin.transactionEventsConfig — receipt listener tuning for streams created from the receiptEvents stream factory."
  validation {
    condition     = try(var.transaction_events.filters.type, null) == null || contains(["public", "private"], try(var.transaction_events.filters.type, ""))
    error_message = "transaction_events.filters.type must be one of: public, private."
  }
  validation {
    condition     = try(var.transaction_events.filters.domain, null) == null || try(var.transaction_events.filters.type, null) == "private"
    error_message = "transaction_events.filters.domain requires transaction_events.filters.type = \"private\"."
  }
  validation {
    condition     = try(var.transaction_events.options.incompleteStateReceiptBehavior, null) == null || contains(["block_contract", "process", "complete_only"], try(var.transaction_events.options.incompleteStateReceiptBehavior, ""))
    error_message = "transaction_events.options.incompleteStateReceiptBehavior must be one of: block_contract, process, complete_only."
  }
}
