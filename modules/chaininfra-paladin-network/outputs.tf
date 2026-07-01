output "network_id" {
  value       = kaleido_platform_network.this.id
  description = "ID of the Paladin network — feeds chaininfra-paladin-node network_id."
}

output "stack_id" {
  value       = kaleido_platform_stack.this.id
  description = "ID of the chain-infrastructure stack — feeds chaininfra-paladin-node stack_id."
}

output "network_name" {
  value       = kaleido_platform_network.this.name
  description = "Name of the Paladin network."
}
