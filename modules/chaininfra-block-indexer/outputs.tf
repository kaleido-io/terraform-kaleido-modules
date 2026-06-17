output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the BlockIndexer service."
}

output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the BlockIndexer runtime."
}

output "block_indexer_name" {
  value       = kaleido_platform_service.this.name
  description = "Display name of the BlockIndexer runtime and service."
}

output "endpoints" {
  value       = kaleido_platform_service.this.endpoints
  description = "Map of the BlockIndexer's published endpoints (ui, rest, ...)."
}

output "hostnames" {
  value       = kaleido_platform_service.this.hostnames
  description = "Map of the BlockIndexer's hostnames."
}
