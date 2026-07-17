variable "node_name" {
  type        = string
  default     = null
  description = "Display name of the CantonParticipantNode (kaleido_platform_runtime, type `CantonParticipantNode`). If not provided, the node will be named `participant-<default_party>`."
}

variable "environment_id" {
  type        = string
  description = "ID of the environment to deploy the CantonSynchronizerNetwork into."
}

variable "validator_network_id" {
  type        = string
  default     = null
  description = "ID of the CantonValidatorNetwork the node joins."
}

variable "synchronizer_network_ids" {
  type        = list(string)
  default     = []
  description = "IDs of the CantonSynchronizerNetworks the node joins."
}

variable "stack_id" {
  type        = string
  description = "ID of the chain-infrastructure (CantonStack) the node belongs to — e.g. the `stack_id` output of the chaininfra-canton-synchronizer-network module."
}

variable "runtime_size" {
  type        = string
  default     = "Medium"
  description = "CantonSynchronizerNodeRuntime size (Medium | Large | ExtraLarge)."
  validation {
    condition     = contains(["Medium", "Large", "ExtraLarge"], var.runtime_size)
    error_message = "runtime_size must be one of: Medium, Large, ExtraLarge."
  }
}

variable "zone" {
  type        = string
  default     = null
  description = "Availability/deployment zone for the runtime. Null uses the platform default."
}

variable "subzone" {
  type        = string
  default     = null
  description = "Subzone for the runtime. Null lets the underlying scheduler choose the best subzone for the runtime within the zone."
}

variable "storage_type" {
  type        = string
  default     = null
  description = "Storage class/type for the runtime's persistent volume. Null uses the platform default."
}

variable "storage_size" {
  type        = number
  default     = null
  description = "Persistent volume size in GB for the runtime. Null uses the platform default."
}

# ─── canton-synchronizer-node-service-config ───────────────────────────────────────────────────

variable "kms_id" {
  type        = string
  description = "ID of the KeyManager the node uses for encryption."
}

variable "kms_wallet_name" {
  type        = string
  description = "Name of the KMS wallet the node uses for encryption."
}

variable "kms_wallet_folder" {
  type        = string
  default     = null
  description = "Folder under the KMS wallet the node uses for encryption."
}

variable "kms_key_spec" {
  type        = string
  default     = "secp256r1"
  description = "Key spec for the Node keys. Must be one of: secp256r1, secp256k1."
  validation {
    condition     = contains(["secp256r1", "secp256k1"], var.kms_key_spec)
    error_message = "kms_key_spec must be one of: secp256r1, secp256k1."
  }
}

variable "hostname_prefix" {
  type        = string
  default     = null
  description = "Prefix for the hostname of the CantonParticipantNode. If not provided, the hostname will be the node name."
}

variable "default_party" {
  type        = string
  description = "Default party for the node."
}

variable "onboarding_secret" {
  type        = string
  description = "Secret for the onboarding of the node."
  sensitive   = true
  default     = null
}