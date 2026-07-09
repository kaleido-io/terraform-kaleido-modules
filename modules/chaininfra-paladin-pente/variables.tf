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

variable "environment_id" {
  type        = string
  description = "ID of the environment holding the ContractManager service and the target Paladin network."
}

variable "contracts_service_id" {
  type        = string
  description = "ID of the ContractManagerService that holds the contract builds and deploy actions."
}

variable "txnmanager_service_id" {
  type        = string
  default     = null
  description = "ID of the TransactionManagerService that submits the factory deploy transaction(s) to the base ledger. Required when mode = deploy. Note: middleware-evm-connector is an EVMConnector, not a TransactionManager — it does not satisfy this."
  validation {
    condition     = var.mode != "deploy" || var.txnmanager_service_id != null
    error_message = "txnmanager_service_id is required when mode = deploy."
  }
}

variable "signing_key_address" {
  type        = string
  default     = null
  description = "cms_action_deploy.signing_key — deploy signer as a 0x… address (kaleido_platform_kms_key address attribute), resolved through the environment's Key Manager. Exactly one of signing_key_address / signing_key_uri is required when mode = deploy. The signer becomes the factory owner and the UUPS upgrade authority, so prefer a dedicated deployer key over a node wallet key. The provider marks signing_key RequiresReplace: switching to the URI form later re-deploys the factory."
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
  description = "cms_action_deploy.signing_key — deploy signer as a Key Manager key URI (kaleido_platform_kms_key uri attribute, shape kld:///keystore/<wallet>/key/<path>). Exactly one of signing_key_address / signing_key_uri is required when mode = deploy. Same ownership and RequiresReplace caveats as signing_key_address."
  validation {
    condition     = var.signing_key_uri == null || startswith(var.signing_key_uri, "kld://")
    error_message = "signing_key_uri must be a Key Manager key URI starting with kld://."
  }
}

variable "mode" {
  type        = string
  default     = "deploy"
  description = "`deploy` builds and deploys the pente factory contract(s) to the base ledger; `existing` composes the domain config around a factory already deployed on the network (joiner accounts). Mirrors registry_mode on chaininfra-paladin-network."
  validation {
    condition     = contains(["deploy", "existing"], var.mode)
    error_message = "mode must be one of: deploy, existing."
  }
}

variable "existing_factory_address" {
  type        = string
  default     = null
  description = "domains.pente.registryAddress — address of the already-deployed pente factory (the ERC1967 proxy address, not the implementation). Required when mode = existing; typically published by the operator account's factory_address output."
  validation {
    condition     = var.mode != "existing" || var.existing_factory_address != null
    error_message = "existing_factory_address is required when mode = existing."
  }
}

variable "create_builds" {
  type        = bool
  default     = true
  description = "Create the cms_build resources so the contract ABIs are visible in this account's ContractManager. Must be true when mode = deploy (the deploy actions reference the builds). Set false in existing mode for pure config composition with no platform resources."
  validation {
    condition     = var.mode != "deploy" || var.create_builds
    error_message = "create_builds must be true when mode = deploy (the deploy actions reference the builds)."
  }
}

variable "plugin_class" {
  type        = string
  default     = "io.kaleido.paladin.pente.domain.PenteDomainFactory"
  description = "domains.pente.plugin.class — Java entry-point class of the pente plugin. Override only if the plugin packaging changes."
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "Prefix for cms_build / cms_action_deploy names — disambiguates multiple networks or module instances sharing one ContractManager."
}

variable "build_path" {
  type        = string
  default     = "Paladin"
  description = "cms_build.path — ContractManager folder the builds are grouped under."
}
