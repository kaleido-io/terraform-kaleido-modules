variable "kaleido_platform_api" {
  type = string
}

variable "kaleido_platform_username" {
  type = string
}

variable "kaleido_platform_password" {
  type      = string
  sensitive = true
}

variable "environment_id" {
  type        = string
  description = "ID of a pre-existing environment. Leave empty to create a new environment named `environment_name`."
  default     = ""
}

variable "environment_name" {
  type        = string
  description = "Name for the environment to create. Only used when `environment_id` is empty."
  default     = "paladin"
}

# ─── Paladin network configuration ──────────────────────────────────────────────

variable "network_name" {
  type        = string
  description = "Name of the Paladin network."
  default     = "paladin-network"
}

variable "node_count" {
  type        = number
  description = "Number of Paladin nodes to create. Node 1 deploys the registry."
  default     = 3
  validation {
    condition     = var.node_count >= 1
    error_message = "node_count must be at least 1 (node 1 deploys the registry)."
  }
}

variable "node_runtime_size" {
  type        = string
  description = "PaladinNodeRuntime size of the nodes (ExtraSmall | Small | Medium | Large | ExtraLarge). Defaults to Large when the Zeto_AnonNullifier implementation is deployed, as its proofs need the memory, and Small otherwise."
  default     = null
}

variable "node_name_prefix" {
  type        = string
  description = "Prefix for Paladin node names (`<prefix>-1` ... `<prefix>-N`)."
  default     = "paladin-node"
}

variable "paladin_ref" {
  type        = string
  description = "Git ref (branch name or commit SHA) of the Paladin repo to source the domain contracts from."
  default     = "5baa0c8e5f8b7b55e5055de9cef2a83b1b361dae"
}

variable "paladin_repo" {
  type        = string
  description = "GitHub repository URL to source the domain contracts from."
  default     = "https://github.com/LFDT-Paladin/paladin"
}

variable "paladin_domains" {
  type        = set(string)
  description = "Paladin domains to deploy and configure on the nodes: any of noto, pente and zeto."
  default     = ["noto", "pente", "zeto"]
  validation {
    condition     = length(setsubtract(var.paladin_domains, ["noto", "pente", "zeto"])) == 0
    error_message = "paladin_domains may only contain noto, pente and zeto."
  }
}

variable "domains" {
  type        = any
  description = "Additional Paladin domain config keyed by domain name, merged over the noto/pente/zeto domains this example deploys."
  default     = {}
}

variable "publish_hostnames" {
  type        = bool
  description = "Publish each node's jsonrpc/jsonrpcws endpoints on a hostname named after the node."
  default     = false
}

# ─── Base ledger + keys ─────────────────────────────────────────────────────────

variable "signing_key_address" {
  type        = string
  description = "Deploy signer for the domain factories as a 0x… address. Overrides the domain-deployer key this example creates."
  default     = null
  validation {
    condition     = var.signing_key_address == null || var.signing_key_uri == null
    error_message = "Set at most one of signing_key_address or signing_key_uri."
  }
}

variable "signing_key_uri" {
  type        = string
  description = "Deploy signer for the domain factories as a Key Manager key URI. Overrides the domain-deployer key this example creates."
  default     = null
}

variable "besu_network_name" {
  type        = string
  description = "Name of the Besu network that serves as the base ledger."
  default     = "paladin-base"
}

variable "paladin_wallet_name" {
  type        = string
  description = "Name of the KMS hdwallet backing the Paladin nodes' keys."
  default     = "paladin-wallet"
}

variable "zeto_implementations" {
  type        = set(string)
  description = "Zeto token implementations to register with the zeto factory: Zeto_Anon and/or Zeto_AnonNullifier."
  default     = ["Zeto_Anon", "Zeto_AnonNullifier"]
}

variable "zeto_contracts_archive_url" {
  type        = string
  description = "Zeto contracts archive (http(s):// or file: URL). Must match the Zeto version of the Paladin node image (v0.2.2 for Paladin v1.0.0)."
  default     = "https://github.com/LFDT-Paladin/zeto/releases/download/v0.2.2/zeto-contracts-v0.2.2.tar.gz"
}

variable "zeto_proving_keys_archive_url" {
  type        = string
  description = "Zeto proving keys archive (http(s):// or file: URL). A file: URL also checks the verifier contracts against it at plan time."
  default     = "https://github.com/LFDT-Paladin/zeto/releases/download/v0.2.2/zeto-test-proving-keys-v0.2.2.tar.gz"
}

variable "zeto_circuits_archive_url" {
  type        = string
  description = "Zeto circuits (wasm) archive (http(s):// or file: URL)."
  default     = "https://github.com/LFDT-Paladin/zeto/releases/download/v0.2.2/zeto-wasm-v0.2.2.tar.gz"
}

variable "zeto_wallet_seeds" {
  type        = list(string)
  description = "BIP39 mnemonic per Paladin node (in node order) for the zeto wallet that derives `zeto.*` identities. Nodes without an entry fall back to a platform-generated seed, which later config updates may not preserve, so set explicit seeds for stable zeto identities."
  default     = []
  sensitive   = true
}
