output "service_id" {
  value       = kaleido_platform_service.this.id
  description = "ID of the PaladinConnector service."
}

output "service_name" {
  value       = kaleido_platform_service.this.name
  description = "Name of the PaladinConnector service."
}

output "stack_id" {
  value       = kaleido_platform_stack.this.id
  description = "ID of the PaladinConnectorStack."
}

output "runtime_id" {
  value       = kaleido_platform_runtime.this.id
  description = "ID of the PaladinConnector runtime."
}

output "endpoints" {
  value       = kaleido_platform_service.this.endpoints
  description = "Map of the connector's published endpoints (the `rest` API at /api/v1)."
}

output "standard_api_name" {
  value       = kaleido_platform_connector_standard_api.paladin.name
  description = "Name of the deployed Paladin standard API."
}

output "standard_api_id" {
  value       = kaleido_platform_connector_standard_api.paladin.id
  description = "ID of the deployed Paladin standard API."
}

output "flow_ids" {
  value = {
    submission       = kaleido_platform_connector_flow.submission.id
    call             = kaleido_platform_connector_flow.call.id
    pgroupCreate     = kaleido_platform_connector_flow.pgroup_create.id
    pgroupSubmission = kaleido_platform_connector_flow.pgroup_submission.id
    pgroupCall       = kaleido_platform_connector_flow.pgroup_call.id
  }
  description = "Map of connector flow name to deployed flow ID."
}

output "flow_names" {
  value = {
    submission       = kaleido_platform_connector_flow.submission.name
    call             = kaleido_platform_connector_flow.call.name
    pgroupCreate     = kaleido_platform_connector_flow.pgroup_create.name
    pgroupSubmission = kaleido_platform_connector_flow.pgroup_submission.name
    pgroupCall       = kaleido_platform_connector_flow.pgroup_call.name
  }
  description = "Map of connector flow name to deployed flow name."
}

output "stream_factory_id" {
  value       = kaleido_platform_connector_stream_factory.receipt_events.id
  description = "ID of the deployed `receiptEvents` connector stream factory."
}

output "standard_stream_id" {
  value       = kaleido_platform_connector_standard_stream.receipt_correlation.id
  description = "ID of the deployed `receiptCorrelation` standard stream."
}

output "config_profiles" {
  value = {
    "paladin.monitoring"              = kaleido_platform_connector_config_profile.monitoring.id
    "paladin.transactionEventsConfig" = kaleido_platform_connector_config_profile.transaction_events.id
    "receiptCorrelation"              = kaleido_platform_connector_config_profile.receipt_correlation.id
  }
  description = "Map of config profile name to deployed config profile ID."
}
