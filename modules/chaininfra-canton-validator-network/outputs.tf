output "network_id" {
  value       = kaleido_platform_network.this.id
  description = "ID of the CantonSynchronizerNetwork."
}

output "stack_id" {
  value       = kaleido_platform_stack.this.id
  description = "ID of the Chain Infrastructure stack wrapping the network."
}