output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the CantonParticipantNodeRuntime."
}

output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the CantonParticipantNodeService."
}

output "endpoints" {
  value       = kaleido_platform_service.this.endpoints
  description = "Map of the CantonParticipantNode's published endpoints (ledger, admin, http, ...)."
}

output "hostnames" {
  value       = kaleido_platform_service.this.hostnames
  description = "Map of the CantonParticipantNode's hostnames."
}