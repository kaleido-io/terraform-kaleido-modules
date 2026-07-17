output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the HTTPConnector service."
}

output "service_name" {
  value       = kaleido_platform_service.this.name
  description = "Name of the HTTPConnector service."
}

output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the HTTPConnector runtime."
}
