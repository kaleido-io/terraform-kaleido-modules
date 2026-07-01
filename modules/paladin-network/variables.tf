variable "environment_id" {
  type        = string
  description = "ID of the environment to create the Paladin Network in."
}

variable "network_name" {
  type        = string
  description = "Name of the Paladin network"
}

variable "config" {
  type        = any
  description = "Configuration object for the Paladin network, serialized to config_json."
  default     = {}
}
