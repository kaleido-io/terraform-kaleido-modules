variable "stack_name" {
  type = string
  description = "Name of the EVM Gateway."
}

variable "environment_id" {
  type = string
  description = "ID of the environment to deploy the EVM Gateway into."
}

variable "network_id" {
  type = string
  description = "ID of the network associated with this stack."
}


variable "runtime_size" {
  type = string
  default = "Small"
  description = "Size of the EVM Gateway runtime."
}

variable "hostname" {
  type = string
  default = null
  description = "Hostname of the EVM Gateway."
}

variable "policies" {
  type = list(object({
    file = optional(string)
    rego = optional(string)
    application_id = string
  }))
  description = "List of policies to deploy the EVM Gateway into. At least one of file or rego must be provided."
}