resource "kaleido_platform_stack" "this" {
  environment = var.environment_id
  name        = var.stack_name
  type        = "web3_middleware"
  sub_type    = "PaladinConnectorStack"
}

resource "kaleido_platform_runtime" "this" {
  type        = "PaladinConnector"
  name        = var.connector_name
  environment = var.environment_id
  stack_id    = kaleido_platform_stack.this.id
  size        = var.runtime_size
  zone        = var.runtime_zone
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "this" {
  type        = "PaladinConnector"
  name        = var.connector_name
  environment = var.environment_id
  stack_id    = kaleido_platform_stack.this.id
  runtime     = kaleido_platform_runtime.this.id

  config_json = jsonencode(local.config_json)
}

locals {
  ecosystem = merge([
    for k, v in {
      name        = var.ecosystem.name
      displayName = var.ecosystem.displayName
    } : { (k) = v } if v != null
  ]...)

  network = var.network == null ? null : merge([
    for k, v in {
      name        = var.network.name
      displayName = var.network.displayName
      chainId     = var.network.chainId
    } : { (k) = v } if v != null
  ]...)

  config_json = merge([
    for k, v in {
      keyManager  = { id = var.key_manager_service_id }
      ecosystem   = local.ecosystem
      network     = local.network
      paladinNode = { id = var.paladin_node_service_id }
    } : { (k) = v } if v != null
  ]...)

  transaction_events_filters = var.transaction_events.filters == null ? null : merge([
    for k, v in {
      type   = var.transaction_events.filters.type
      domain = var.transaction_events.filters.domain
    } : { (k) = v } if v != null
  ]...)

  transaction_events_options = var.transaction_events.options == null ? null : merge([
    for k, v in {
      domainReceipts                 = var.transaction_events.options.domainReceipts
      incompleteStateReceiptBehavior = var.transaction_events.options.incompleteStateReceiptBehavior
    } : { (k) = v } if v != null
  ]...)

  transaction_events_value = merge([
    for k, v in {
      pollTimeout = var.transaction_events.pollTimeout
      batchSize   = var.transaction_events.batchSize
      unfiltered  = var.transaction_events.unfiltered
      filters     = local.transaction_events_filters
      options     = local.transaction_events_options
    } : { (k) = v } if v != null
  ]...)
}

resource "kaleido_platform_connector_config_type" "monitoring" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "paladin.monitoring"
}

resource "kaleido_platform_connector_config_type" "transaction_events" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "paladin.transactionEventsConfig"
}

resource "kaleido_platform_connector_config_profile" "monitoring" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "paladin.monitoring"
  config_type = kaleido_platform_connector_config_type.monitoring.name
  value_json  = jsonencode(var.monitoring)
}

resource "kaleido_platform_connector_config_profile" "transaction_events" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "paladin.transactionEventsConfig"
  config_type = kaleido_platform_connector_config_type.transaction_events.name
  value_json  = jsonencode(local.transaction_events_value)
}

resource "kaleido_platform_connector_config_profile" "receipt_correlation" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "receiptCorrelation"
  config_type = kaleido_platform_connector_config_type.transaction_events.name
  value_json = jsonencode({
    pollTimeout = "1s"
    batchSize   = 50
    unfiltered  = true
  })
}

resource "kaleido_platform_connector_flow" "submission" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "submission"
  config_type_bindings = {
    "paladin.monitoring" = kaleido_platform_connector_config_profile.monitoring.name
  }
}

resource "kaleido_platform_connector_flow" "call" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "call"
}

resource "kaleido_platform_connector_flow" "pgroup_create" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "pgroupCreate"
  config_type_bindings = {
    "paladin.monitoring" = kaleido_platform_connector_config_profile.monitoring.name
  }
}

resource "kaleido_platform_connector_flow" "pgroup_submission" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "pgroupSubmission"
  config_type_bindings = {
    "paladin.monitoring" = kaleido_platform_connector_config_profile.monitoring.name
  }
}

resource "kaleido_platform_connector_flow" "pgroup_call" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "pgroupCall"
}

resource "kaleido_platform_connector_stream_factory" "receipt_events" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "receiptEvents"
  depends_on  = [kaleido_platform_connector_config_type.transaction_events]
}

resource "kaleido_platform_connector_standard_api" "paladin" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "paladin"
  flow_type_bindings = {
    submission       = kaleido_platform_connector_flow.submission.name
    call             = kaleido_platform_connector_flow.call.name
    pgroupCreate     = kaleido_platform_connector_flow.pgroup_create.name
    pgroupSubmission = kaleido_platform_connector_flow.pgroup_submission.name
    pgroupCall       = kaleido_platform_connector_flow.pgroup_call.name
  }
}

resource "kaleido_platform_connector_standard_stream" "receipt_correlation" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "receiptCorrelation"
  config_profile_name_or_id = kaleido_platform_connector_config_profile.receipt_correlation.name
  depends_on                = [kaleido_platform_connector_stream_factory.receipt_events]
}
