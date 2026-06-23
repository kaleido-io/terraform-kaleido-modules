output "network_id" {
  value       = kaleido_platform_network.this.id
  description = "ID of the CantonSynchronizerNetwork."
}

output "stack_id" {
  value       = try(kaleido_platform_stack.this[0].id, null)
  description = "ID of the Chain Infrastructure stack wrapping the network."
}