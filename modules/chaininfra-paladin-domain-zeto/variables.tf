variable "paladin_ref" {
  type        = string
  description = "Git ref (branch name or commit SHA) of the Paladin repo to source the ZetoFactory contract from. Pin to a commit SHA for reproducible builds; changing the ref replaces the builds and, in deploy mode, re-deploys the factory."
  validation {
    condition     = length(var.paladin_ref) > 0
    error_message = "paladin_ref must be a non-empty branch name or commit SHA."
  }
}

variable "paladin_repo" {
  type        = string
  default     = "https://github.com/LFDT-Paladin/paladin"
  description = "GitHub repository URL to source the ZetoFactory contract from. Defaults to the open-source Paladin repo; point at a fork to build from it instead."
  validation {
    condition     = startswith(var.paladin_repo, "https://github.com/")
    error_message = "paladin_repo must be a GitHub repository URL of the form https://github.com/<org>/<repo>."
  }
}

variable "implementations" {
  type        = set(string)
  default     = ["Zeto_Anon"]
  description = "Zeto token implementations to register with the factory and configure in the domain: Zeto_Anon and/or Zeto_AnonNullifier. Tokens are deployed from the factory by implementation name. In join modes, list the implementations registered on the existing factory."
  validation {
    condition     = length(var.implementations) > 0 && length(setsubtract(var.implementations, ["Zeto_Anon", "Zeto_AnonNullifier"])) == 0
    error_message = "implementations must list at least one of: Zeto_Anon, Zeto_AnonNullifier."
  }
}

variable "contracts_archive_url" {
  type        = string
  description = "Location of the Zeto contracts archive (.zip, .tar.gz, .tgz or .gz) holding the compiled token implementations, Groth16 verifiers and libraries as Hardhat artifact JSON files, e.g. the zeto-contracts-<version>.tar.gz release asset. An http(s):// URL, or a local file as file:///abs/path or file:relative/path. Read on every plan. Its version must match the proving keys and circuits."
  validation {
    condition     = can(regex("^(https?://|file:)", var.contracts_archive_url))
    error_message = "contracts_archive_url must be an http://, https:// or file: URL."
  }
}

variable "proving_keys_archive_url" {
  type        = string
  description = "Location of the Zeto proving keys archive (<circuit>.zkey and <circuit>-vkey.json files), e.g. the zeto-test-proving-keys-<version>.tar.gz release asset; must come from the same trusted setup as the verifier contracts. An http(s):// URL, or a local file as a file: URL. Passed to the nodes through the node_zeto_artifacts output. When it is a file: URL the module also checks, at plan time, that each verifier contract matches its verification key."
  validation {
    condition     = can(regex("^(https?://|file:)", var.proving_keys_archive_url))
    error_message = "proving_keys_archive_url must be an http://, https:// or file: URL."
  }
}

variable "circuits_archive_url" {
  type        = string
  description = "Location of the Zeto circuits archive (<circuit>_js/<circuit>.wasm files), e.g. the zeto-wasm-<version>.tar.gz release asset. An http(s):// URL, or a local file as a file: URL. Passed to the nodes through the node_zeto_artifacts output."
  validation {
    condition     = can(regex("^(https?://|file:)", var.circuits_archive_url))
    error_message = "circuits_archive_url must be an http://, https:// or file: URL."
  }
}

variable "factory_initializer_selector" {
  type        = string
  default     = "0x8129fc1c"
  description = "4-byte function selector of the ZetoFactory initializer, delegatecalled by the ERC1967 proxy at deploy time with no arguments. Defaults to the selector for initialize(). Override only if the factory initializer function changes in the pinned paladin_ref."
  validation {
    condition     = can(regex("^0x[0-9a-fA-F]{8}$", var.factory_initializer_selector))
    error_message = "factory_initializer_selector must be a 0x-prefixed 4-byte function selector, e.g. 0x8129fc1c."
  }
}

variable "snark_prover_dir" {
  type        = string
  default     = "/app/domains/zeto/zkp"
  description = "Directory on the Paladin nodes holding the Zeto circuits and proving keys (snarkProver.circuitsDir / snarkProver.provingKeysDir). Defaults to the directory built into the Paladin node image, until the platform can install the archives given in proving_keys_archive_url and circuits_archive_url on the nodes."
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
  description = "ID of the EVMConnector service whose standard API submits the factory deploy and registration transactions to the base ledger. Required when mode = deploy."
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
  description = "0x… address of the intended Zeto factory deployer. It becomes the factory owner and signs the token implementation registration."
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
  description = "URI of the intended Zeto factory deployer. It becomes the factory owner and signs the token implementation registration."
  validation {
    condition     = var.signing_key_uri == null ? true : startswith(var.signing_key_uri, "kld://")
    error_message = "signing_key_uri must be a Kaleido Key Manager key URI starting with kld://."
  }
}

variable "mode" {
  type        = string
  default     = "deploy"
  description = "`deploy` builds and deploys the zeto factory and, for each of the implementations, its verifiers, libraries and token contract, and registers it with the factory. `join_with_builds` builds the contracts in this account's ContractManager (for ABI visibility) but uses a pre-existing deployment. `join` also uses a pre-existing deployment, with no ContractManager resources created."
  validation {
    condition     = contains(["deploy", "join", "join_with_builds"], var.mode)
    error_message = "mode must be one of: deploy, join, join_with_builds."
  }
}

variable "factory_address" {
  type        = string
  default     = null
  description = "Address of an already-deployed zeto factory with the implementations registered (ERC1967 proxy address). Required when mode = join or mode = join_with_builds."
  validation {
    condition     = var.mode == "deploy" || var.factory_address != null
    error_message = "factory_address is required when mode = join or mode = join_with_builds."
  }
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "Prefix for ContractManager build names. The connector deploys have no name; their identity is an idempotency key derived from the deployment inputs."
}

variable "build_path" {
  type        = string
  default     = "Paladin"
  description = "ContractManager folder the builds are grouped under."
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
