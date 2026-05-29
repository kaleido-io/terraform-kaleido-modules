output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the BesuNode service."
}

output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the BesuNode runtime."
}

output "node_name" {
  value       = kaleido_platform_service.this.name
  description = "Display name of the BesuNode runtime and service."
}

output "connectivity_json" {
  value       = kaleido_platform_service.this.connectivity_json
  description = "Peer connectivity descriptor for the node, e.g. for building network connectors between members."
}

output "endpoints" {
  value       = kaleido_platform_service.this.endpoints
  description = "Map of the node's published endpoints (jsonrpc, jsonrpcws, graphql, rest, ...)."
}

output "hostnames" {
  value       = kaleido_platform_service.this.hostnames
  description = "Map of the node's hostnames."
}
