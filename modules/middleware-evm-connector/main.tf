# ─── Stack + Runtime + Service ────────────────────────────────────────────────

resource "kaleido_platform_stack" "this" {
  environment = var.environment_id
  name        = var.stack_name
  type        = "web3_middleware"
  sub_type    = "EVMConnectorStack"
}

resource "kaleido_platform_runtime" "this" {
  type        = "EVMConnector"
  name        = var.connector_name
  environment = var.environment_id
  stack_id    = kaleido_platform_stack.this.id
  size        = var.runtime_size
  zone        = var.runtime_zone
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "this" {
  type        = "EVMConnector"
  name        = var.connector_name
  environment = var.environment_id
  stack_id    = kaleido_platform_stack.this.id
  runtime     = kaleido_platform_runtime.this.id

  config_json = jsonencode(merge(
    { keyManager = { id = var.key_manager_service_id } },
    var.ecosystem              != null ? { ecosystem  = var.ecosystem  } : {},
    var.network                != null ? { network    = var.network    } : {},
    var.evm_gateway_service_id != null ? { evmGateway = { id = var.evm_gateway_service_id } } : {},
    var.jsonrpc_url            != null ? { url        = var.jsonrpc_url } : {},
    # The upstream evm-connector-service-config schema rejects inlined
    # username/password under `auth`; basic-auth credentials must be supplied
    # via a credSet on the service. Reference the credSet by name here, and
    # the actual values are set in `cred_sets` below.
    var.jsonrpc_auth           != null ? { auth       = { credSetRef = "rpc_auth" } } : {},
  ))

  cred_sets = var.jsonrpc_auth != null ? {
    rpc_auth = {
      type = "basic_auth"
      basic_auth = {
        username = var.jsonrpc_auth.username
        password = var.jsonrpc_auth.password
      }
    }
  } : {}

  database_name = var.database_name
}

# ─── Config types (template ensure / version pin) ─────────────────────────────

locals {
  config_types = toset([
    "evm.confirmations",
    "evm.gasEstimation",
    "evm.gasPricing",
    "evm.nonceAssignment",
    "evm.submission",
    "evm.transactionSerialization",
    "evm.blockEventsConfig",
    "evm.transactionEventsConfig",
    "evm.contractEventListener",
  ])

  # Standard profiles: keyed by config type, value = { profile_name, config (name field excluded) }.
  # Only includes types whose variable is non-null (null = dynamic binding, no standard profile).
  standard_profiles = {
    for config_type, var_value in {
      "evm.confirmations"            = var.confirmations
      "evm.gasEstimation"            = var.gas_estimation
      "evm.gasPricing"               = var.gas_pricing
      "evm.nonceAssignment"          = var.nonce_assignment
      "evm.submission"               = var.submission
      "evm.transactionSerialization" = var.transaction_serialization
      "evm.blockEventsConfig"        = var.block_events
      "evm.transactionEventsConfig"  = var.transaction_events
      "evm.contractEventListener"    = var.contract_event_listener
    } : config_type => {
      profile_name = try(var_value.name, null) != null ? var_value.name : config_type
      config       = { for k, v in var_value : k => v if k != "name" }
    }
    if var_value != null
  }

  # Named profiles for JSONata selection — keyed as "config_type::profile_name" to avoid collisions.
  # Values are pre-encoded to JSON so the merged map has a uniform type.
  all_named_profiles = merge(
    { for k, v in var.confirmations_profiles             : "evm.confirmations::${k}"             => { config_type = "evm.confirmations",            profile_name = k, value_json = jsonencode(v) } },
    { for k, v in var.gas_estimation_profiles            : "evm.gasEstimation::${k}"             => { config_type = "evm.gasEstimation",            profile_name = k, value_json = jsonencode(v) } },
    { for k, v in var.gas_pricing_profiles               : "evm.gasPricing::${k}"                => { config_type = "evm.gasPricing",               profile_name = k, value_json = jsonencode(v) } },
    { for k, v in var.nonce_assignment_profiles          : "evm.nonceAssignment::${k}"           => { config_type = "evm.nonceAssignment",          profile_name = k, value_json = jsonencode(v) } },
    { for k, v in var.submission_profiles                : "evm.submission::${k}"                => { config_type = "evm.submission",               profile_name = k, value_json = jsonencode(v) } },
    { for k, v in var.transaction_serialization_profiles : "evm.transactionSerialization::${k}"  => { config_type = "evm.transactionSerialization", profile_name = k, value_json = jsonencode(v) } },
  )

  # Dynamic mapping per submission-flow type (null = use static binding).
  dynamic_mappings = {
    "evm.confirmations"            = var.confirmations_dynamic_mapping
    "evm.gasEstimation"            = var.gas_estimation_dynamic_mapping
    "evm.gasPricing"               = var.gas_pricing_dynamic_mapping
    "evm.nonceAssignment"          = var.nonce_assignment_dynamic_mapping
    "evm.submission"               = var.submission_dynamic_mapping
    "evm.transactionSerialization" = var.transaction_serialization_dynamic_mapping
  }

  # Static bindings: submission-flow types where the standard profile exists AND no dynamic mapping.
  submission_static_bindings = {
    for config_type, profile_info in local.standard_profiles :
    config_type => kaleido_platform_connector_config_profile.this[config_type].id
    if try(local.dynamic_mappings[config_type], null) == null
  }

  # Dynamic bindings: submission-flow types where a dynamic mapping is configured.
  submission_dynamic_bindings = {
    for config_type, dm in local.dynamic_mappings :
    config_type => dm
    if dm != null
  }
}

resource "kaleido_platform_connector_config_type" "this" {
  for_each    = local.config_types
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = each.key
}

# ─── Config profiles ──────────────────────────────────────────────────────────

resource "kaleido_platform_connector_config_profile" "this" {
  for_each    = local.standard_profiles
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = each.value.profile_name
  config_type = each.key
  value_json  = jsonencode(each.value.config)
  depends_on  = [kaleido_platform_connector_config_type.this]
}

# ─── Named profiles for dynamic selection ────────────────────────────────────

resource "kaleido_platform_connector_config_profile" "named" {
  for_each    = local.all_named_profiles
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = each.value.profile_name
  config_type = each.value.config_type
  value_json  = each.value.value_json
  depends_on  = [kaleido_platform_connector_config_type.this]
}

# ─── Connector flows ──────────────────────────────────────────────────────────

resource "kaleido_platform_connector_flow" "submission" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "submission"
}

resource "kaleido_platform_connector_flow" "query" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "query"
}

# ─── Submission flow config-profile bindings ──────────────────────────────────

# Static bindings: profile bound by ID for each type without a dynamic mapping.
resource "kaleido_platform_connector_flow_config_binding" "submission_static" {
  for_each          = local.submission_static_bindings
  environment       = var.environment_id
  service           = kaleido_platform_service.this.id
  flow              = kaleido_platform_connector_flow.submission.name
  config_type       = each.key
  config_profile_id = each.value
}

# Dynamic bindings: JSONata expression on the binding slot.
# Mutually exclusive with the corresponding standard profile variable — set
# <type> = null when using <type>_dynamic_mapping.
resource "kaleido_platform_connector_flow_config_binding" "submission_dynamic" {
  for_each    = local.submission_dynamic_bindings
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  flow        = kaleido_platform_connector_flow.submission.name
  config_type = each.key
  dynamic_mapping = {
    name_prefix = "${kaleido_platform_service.this.id}/"
    jsonata     = each.value.jsonata
  }
  depends_on = [
    kaleido_platform_connector_config_profile.this,
    kaleido_platform_connector_config_profile.named,
  ]
  lifecycle {
    precondition {
      condition     = !contains(keys(local.standard_profiles), each.key)
      error_message = "${each.key}: set the profile variable to null when using dynamic mapping — they are mutually exclusive."
    }
  }
}

# ─── Stream factories ─────────────────────────────────────────────────────────

resource "kaleido_platform_connector_stream_factory" "block_events" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "blockEvents"
  depends_on  = [kaleido_platform_connector_config_type.this]
}

resource "kaleido_platform_connector_stream_factory" "transaction_events" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "transactionEvents"
  depends_on  = [kaleido_platform_connector_config_type.this]
}

# ─── Standard API ─────────────────────────────────────────────────────────────

resource "kaleido_platform_connector_standard_api" "evm" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "evm"
  # Keys are connector-flow TYPES (as declared by the upstream evm standard-api
  # template's subflowBindingTypes values), not binding names. The template's
  # `resolve` and `submit` bindings both require a flow of type `submission`.
  flow_type_bindings = {
    submission = kaleido_platform_connector_flow.submission.name
    query      = kaleido_platform_connector_flow.query.name
  }
}

# ─── Standard streams ─────────────────────────────────────────────────────────

resource "kaleido_platform_connector_standard_stream" "new_blocks" {
  environment               = var.environment_id
  service                   = kaleido_platform_service.this.id
  name                      = "newBlocks"
  config_profile_name_or_id = kaleido_platform_connector_config_profile.this["evm.blockEventsConfig"].name
  depends_on                = [kaleido_platform_connector_stream_factory.block_events]
}
