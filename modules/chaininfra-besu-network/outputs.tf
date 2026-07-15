output "network_id" {
  value       = kaleido_platform_network.this.id
  description = "ID of the BesuNetwork." 
}

output "stack_id" {
  value       = kaleido_platform_stack.this.id
  description = "ID of the chain-infrastructure stack wrapping the network."
}

output "network_name" {
  value       = kaleido_platform_network.this.name
  description = "Display name of the BesuNetwork."
}

output "chain_id" {
  value       = try(kaleido_platform_network.this.info["chainID"], null)
  description = "Base ledger chain ID." 
}

output "network_info" {
  value       = kaleido_platform_network.this.info
  description = "Network configuration."
}
