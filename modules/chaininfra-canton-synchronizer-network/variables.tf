variable "stack_enabled" {
  type = bool
  default = true
  description = "To create a Chain Infrastructure stack for the CantonSynchronizerNetwork."
}

variable "stack_name" {
  type = string
  default = null
  description = "Optional name of the Chain Infrastructure stack for the CantonSynchronizerNetwork. If not provided, the network will be created without a stack."
}

variable "environment_id" {
  type = string
  description = "ID of the environment to deploy the CantonSynchronizerNetwork into."
}

variable "network_name" {
  type = string
  default = "local-synchronizer"
  description = "Display name of the CantonSynchronizerNetwork (kaleido_platform_network, type `CantonSynchronizer`)."
}

variable "external_sequencer_endpoint" {
  type = string
  default = null
  description = "Optional external sequencer endpoint for the CantonSynchronizerNetwork. If not provided, the network will be created without a sequencer."
}