variable "stack_name" {
  type = string
  default = null
  description = "Name of the Chain Infrastructure stack for the CantonValidatorNetwork. If not provided, the stack will be created name as `network_type`."
}

variable "environment_id" {
  type = string
  description = "ID of the environment to deploy the CantonValidatorNetwork into."
}

variable "network_name" {
  type = string
  default = null
  description = "Name of the CantonValidatorNetwork. If not provided, the network will be created name as `network_type`."
}

variable "network_type" {
  type = string
  description = "Type of network to use for the CantonValidatorNetwork. Must be one of: Sandbox, Global."
  validation {
    condition = contains(["Sandbox", "Devnet", "Testnet", "Mainnet"], var.network_type)
    error_message = "network_type must be one of: Sandbox, Devnet, Testnet, Mainnet."
  }
}

variable "sponsor_super_validator" {
  type = string
  default = "Digital-Asset-1"
  description = "Name of the sponsor super validator to use for the CantonValidatorNetwork."
  validation {
    condition = var.sponsor_super_validator == null || contains(["Digital-Asset-1", "Digital-Asset-2", "Global-Synchronizer-Foundation", "Cumberland-1", "Cumberland-2"], var.sponsor_super_validator)
    error_message = "sponsor_super_validator must be one of: Digital-Asset-1, Digital-Asset-2, Global-Synchronizer-Foundation, Cumberland-1, Cumberland-2."
  }
}