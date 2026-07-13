variable "environment_id" {
  type        = string
  description = "ID of the Kaleido environment to create the Paladin network in."
}

variable "network_name" {
  type        = string
  description = "Name of the Paladin network."
}

variable "stack_name" {
  type        = string
  default     = null
  description = "Name of the chain-infrastructure stack. Defaults to network_name."
}

variable "registry_mode" {
  type        = string
  default     = "deploy"
  description = "`deploy` has the platform deploy a new EVM registry contract via the registry node; `existing` joins a registry already deployed on the base ledger."
  validation {
    condition     = contains(["deploy", "existing"], var.registry_mode)
    error_message = "registry_mode must be one of: deploy, existing."
  }
}

variable "existing_registry_address" {
  type        = string
  default     = null
  description = "address of the already-deployed EVM registry contract. Required when registry_mode = existing."
  validation {
    condition     = var.registry_mode != "existing" || var.existing_registry_address != null
    error_message = "existing_registry_address is required when registry_mode = existing."
  }
}

variable "registry_node" {
  type        = string
  default     = null
  description = "Name of the PaladinNodeService that deploys the EVM registry (by convention the first node). Required when registry_mode = deploy; must match the `node_name` of a chaininfra-paladin-node created against this network."
  validation {
    condition     = var.registry_mode != "deploy" || var.registry_node != null
    error_message = "registry_node is required when registry_mode = deploy."
  }
}
