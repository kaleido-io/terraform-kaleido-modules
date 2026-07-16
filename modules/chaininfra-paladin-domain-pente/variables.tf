variable "paladin_ref" {
  type        = string
  description = "Git ref (branch name or commit SHA) of the Paladin repo to source the Pente contracts from. Pin to a commit SHA for reproducible builds; changing the ref replaces the builds and, in deploy mode, re-deploys the factory."
  validation {
    condition     = length(var.paladin_ref) > 0
    error_message = "paladin_ref must be a non-empty branch name or commit SHA."
  }
}

variable "paladin_repo" {
  type        = string
  default     = "https://github.com/LFDT-Paladin/paladin"
  description = "GitHub repository URL to source the Pente contracts from. Defaults to the open-source Paladin repo; point at a fork to build from it instead."
  validation {
    condition     = startswith(var.paladin_repo, "https://github.com/")
    error_message = "paladin_repo must be a GitHub repository URL of the form https://github.com/<org>/<repo>."
  }
}

variable "factory_initializer_selector" {
  type        = string
  default     = "0x8129fc1c"
  description = "4-byte function selector of the PenteFactory initializer, delegatecalled by the ERC1967 proxy at deploy time. Defaults to the selector for initialize(). Override only if the factory initializer function changes in the pinned paladin_ref."
  validation {
    condition     = can(regex("^0x[0-9a-fA-F]{8}$", var.factory_initializer_selector))
    error_message = "factory_initializer_selector must be a 0x-prefixed 4-byte function selector, e.g. 0x8129fc1c."
  }
}

variable "environment_id" {
  type        = string
  description = "ID of the environment holding the ContractManager service and the target Paladin network."
}

variable "contracts_service_id" {
  type        = string
  description = "ID of the ContractManagerService that holds the contract builds."
}

variable "connector_service_id" {
  type        = string
  default     = null
  description = "ID of the EVMConnector service whose standard API submits the factory deploy transaction(s) to the base ledger. Required when mode = deploy."
  validation {
    condition     = var.mode != "deploy" || var.connector_service_id != null
    error_message = "connector_service_id is required when mode = deploy."
  }
}

variable "connector_api_name" {
  type        = string
  default     = "evm"
  description = "Name of the EVM standard API deployed on the connector (standard_api_name output of middleware-evm-connector)."
}

variable "signing_key_address" {
  type        = string
  default     = null
  description = "deploy signer as a 0x… address (kaleido_platform_kms_key address attribute), resolved through the environment's Key Manager. Exactly one of signing_key_address / signing_key_uri is required when mode = deploy."
  validation {
    condition = var.mode != "deploy" || (
      (var.signing_key_address != null) != (var.signing_key_uri != null)
    )
    error_message = "Exactly one of signing_key_address or signing_key_uri is required when mode = deploy."
  }
}

variable "signing_key_uri" {
  type        = string
  default     = null
  description = "deploy signer as a Key Manager key URI (kaleido_platform_kms_key uri attribute, shape kld:///keystore/<wallet>/key/<path>). Exactly one of signing_key_address / signing_key_uri is required when mode = deploy."
  validation {
    condition     = var.signing_key_uri == null || startswith(var.signing_key_uri, "kld://")
    error_message = "signing_key_uri must be a Key Manager key URI starting with kld://."
  }
}

variable "mode" {
  type        = string
  default     = "deploy"
  description = "`deploy` builds and deploys the pente factory contract(s). `join_with_builds` builds the contracts in this account's ContractManager (for ABI visibility) but uses a pre-existing deployment. `join` also uses a pre-existing deployment, with no ContractManager resources created."
  validation {
    condition     = contains(["deploy", "join", "join_with_builds"], var.mode)
    error_message = "mode must be one of: deploy, join, join_with_builds."
  }
}

variable "existing_factory_address" {
  type        = string
  default     = null
  description = "address of the already-deployed pente factory (ERC1967 proxy address). Required when mode = join or mode = join_with_builds; typically published by the deploying call's factory_address output."
  validation {
    condition     = var.mode == "deploy" || var.existing_factory_address != null
    error_message = "existing_factory_address is required when mode = join or mode = join_with_builds."
  }
}

variable "plugin_class" {
  type        = string
  default     = "io.kaleido.paladin.pente.domain.PenteDomainFactory"
  description = "Java entry-point class of the pente plugin. Override only if the plugin packaging changes."
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "Prefix for ContractManagerService build names. The connector deploys have no name; their identity is an idempotency key derived from the deployment inputs."
}

variable "build_path" {
  type        = string
  default     = "Paladin"
  description = "ContractManagerService folder the builds are grouped under."
}

variable "contract_optimizer" {
  type = object({
    enabled = optional(bool)
    runs    = optional(number)
    via_ir  = optional(bool)
  })
  default     = { enabled = true, runs = 200, via_ir = true }
  description = "Solc optimizer settings applied to all contract builds."
}
