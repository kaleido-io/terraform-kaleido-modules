output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the CantonSuperValidatorNodeRuntime."
}

output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the CantonSuperValidatorNodeService."
}

output "endpoints" {
  value       = kaleido_platform_service.this.endpoints
  description = "Map of the CantonSuperValidatorNode's published endpoints (sequencer, admin, mediator, ...)."
}

output "hostnames" {
  value       = kaleido_platform_service.this.hostnames
  description = "Map of the CantonSuperValidatorNode's hostnames."
}