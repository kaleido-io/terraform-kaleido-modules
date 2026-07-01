output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the PaladinNodeService."
}

output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the PaladinNodeRuntime."
}

output "node_name" {
  value       = kaleido_platform_service.this.name
  description = "Display name of the Paladin node runtime and service."
}

output "endpoints" {
  value       = kaleido_platform_service.this.endpoints
  description = "Map of the node's published endpoints (jsonrpc, jsonrpcws, ...)."
}

output "hostnames" {
  value       = kaleido_platform_service.this.hostnames
  description = "Map of the node's hostnames."
}

output "registry_address" {
  value       = var.read_registry_address ? data.kaleido_platform_paladin_evm_registry.this[0].address : null
  description = "Address of the network's EVM registry contract, read back after deployment. Only set on the registry-admin node with read_registry_address = true (deploy-mode bootstrap: the address doesn't exist until the admin node has run). Joiner networks consume this as chaininfra-paladin-network existing_registry_address."
}
