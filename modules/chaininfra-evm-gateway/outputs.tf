output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the EVM Gateway service."
}

output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the EVM Gateway runtime."
}

output "evm_gateway_name" {
  value       = kaleido_platform_service.this.name
  description = "Display name of the EVM Gateway runtime and service."
}

output "endpoints" {
  value       = kaleido_platform_service.this.endpoints
  description = "Map of the EVM Gateway's published endpoints (jsonrpc, jsonrpcws, graphql, rest, ...)."
}

output "hostnames" {
  value       = kaleido_platform_service.this.hostnames
  description = "Map of the EVM Gateway's hostnames."
}