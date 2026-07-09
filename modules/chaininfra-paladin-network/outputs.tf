output "network_id" {
  value       = kaleido_platform_network.this.id
  description = "ID of the Paladin network"
}

output "stack_id" {
  value       = kaleido_platform_stack.this.id
  description = "ID of the chain-infrastructure stack"
}

output "network_name" {
  value       = kaleido_platform_network.this.name
  description = "Name of the Paladin network."
}

output "registry" {
  value = {
    mode  = var.registry_mode
    admin = var.registry_admin
  }
  description = "The network's EVM registry configuration"
}
