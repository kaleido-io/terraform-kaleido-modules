variable "gateway_name" {
  type = string
  description = "Name of the EVM Gateway."
}

variable "environment_id" {
  type = string
  description = "ID of the environment to deploy the EVM Gateway into."
}

variable "network_id" {
  type = string
  description = "ID of the network to deploy the EVM Gateway into."
}

variable "stack_id" {
  type = string
  default = null
  description = "Optional ID of the stack to deploy the EVM Gateway into. If not provided, the gateway will be created outside of the stack."
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