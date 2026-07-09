variable "paladin_ref" {
  type        = string
  description = "Git ref (branch name or commit SHA) of the Paladin repo to source the Noto contracts from. Pin to a commit SHA for reproducible builds; changing the ref replaces the builds and, in deploy mode, re-deploys the factory."
  validation {
    condition     = length(var.paladin_ref) > 0
    error_message = "paladin_ref must be a non-empty branch name or commit SHA."
  }
}

variable "paladin_repo" {
  type        = string
  default     = "https://github.com/LFDT-Paladin/paladin"
  description = "GitHub repository URL to source the Noto contracts from. Defaults to the open-source Paladin repo; point at a fork to build from it instead."
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
  description = "ID of the TransactionManagerService that submits the factory deploy transaction(s) to the base ledger"
  validation {
    condition     = var.mode != "deploy" || var.txnmanager_service_id != null
    error_message = "txnmanager_service_id is required when mode = deploy."
  }
}

variable "signing_key_address" {
  type        = string
  default     = null
  description = "0x… address of the intended Noto factory deployer."
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
  description = "URI of the intended Noto factory deployer."
  validation {
    condition     = var.signing_key_uri == null || startswith(var.signing_key_uri, "kld://")
    error_message = "signing_key_uri must be a Kaleido Key Manager key URI starting with kld://."
  }
}

variable "mode" {
  type        = string
  default     = "deploy"
  description = "`deploy` builds and deploys the noto factory contract(s) to the base ledger; `existing` composes the domain config around a factory already deployed on the network."
  validation {
    condition     = contains(["deploy", "existing"], var.mode)
    error_message = "mode must be one of: deploy, existing."
  }
}

variable "existing_factory_address" {
  type        = string
  default     = null
  description = "Address of an already-deployed noto factory (ERC1967 proxy address). Required when mode='existing'."
  validation {
    condition     = var.mode != "existing" || var.existing_factory_address != null
    error_message = "existing_factory_address is required when mode = existing."
  }
}

variable "create_builds" {
  type        = bool
  default     = true
  description = "Create the builds resources so the contract ABIs are visible in this account's ContractManager. Must be true when mode = deploy (the deploy actions reference the builds). Set false in existing mode for pure config composition with no platform resources."
  validation {
    condition     = var.mode != "deploy" || var.create_builds
    error_message = "create_builds must be true when mode = deploy (the deploy actions reference the builds)."
  }
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "Prefix for ContractManager build / deploy names"
}

variable "build_path" {
  type        = string
  default     = "Paladin"
  description = "ContractManager folder the builds are grouped under."
}
