output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the EVM Gateway service."
}

output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the EVM Gateway runtime."
}

output "stack_id" {
  value       = kaleido_platform_stack.this.id
  description = "ID of the Blockchain Application Firewall stack."
}

output "endpoints" {
  value       = kaleido_platform_service.this.endpoints
  description = "Map of the EVM Gateway's published endpoints (jsonrpc, jsonrpcws, graphql, rest, ...)."
}

output "hostnames" {
  value       = kaleido_platform_service.this.hostnames
  description = "Map of the EVM Gateway's hostnames."
}