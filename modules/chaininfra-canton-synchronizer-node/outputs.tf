output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the CantonSynchronizerNodeRuntime."
}

output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the CantonSynchronizerNodeService."
}

output "endpoints" {
  value       = kaleido_platform_service.this.endpoints
  description = "Map of the CantonSynchronizerNode's published endpoints (sequencer, admin, mediator, ...)."
}

output "hostnames" {
  value       = kaleido_platform_service.this.hostnames
  description = "Map of the CantonSynchronizerNode's hostnames."
}