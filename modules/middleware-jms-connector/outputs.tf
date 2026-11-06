output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the JMSConnectorService."
}

output "service_name" {
  value       = kaleido_platform_service.this.name
  description = "Name of the JMSConnectorService."
}

output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the JMSConnectorRuntime."
}

output "provider_name" {
  value       = replace(kaleido_platform_service.this.id, ":", "-")
  description = "The connector's provider name, which workflow engine streams and workflows reference it by: the service ID with ':' replaced by '-'."
}

output "registry_namespace" {
  value       = kaleido_platform_service.this.registry_namespace
  description = "Artifact registry namespace of the client jars."
}
