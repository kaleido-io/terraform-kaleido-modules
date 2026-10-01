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
    "evm.prioritization",
    "evm.submission",
    "evm.transactionSerialization",
    "evm.blockEventsConfig",
    "evm.transactionEventsConfig",
    "evm.contractEventListener",
  ])

  # Optional config types of the submission flow get a profile, and a binding, only when set - the
  # same as configuring the connector in the console, which deploys the type and leaves it unbound.
  optional_profile_values = {
    for t, v in { "evm.prioritization" = var.prioritization } : t => v if v != null
  }

  profile_values = merge({
    "evm.confirmations"            = var.confirmations
    "evm.gasEstimation"            = var.gas_estimation
    "evm.gasPricing"               = var.gas_pricing
    "evm.nonceAssignment"          = var.nonce_assignment
    "evm.submission"               = var.submission
    "evm.transactionSerialization" = var.transaction_serialization
    "evm.blockEventsConfig"        = var.block_events
    "evm.transactionEventsConfig"  = var.transaction_events
    "evm.contractEventListener"    = var.contract_event_listener
  }, local.optional_profile_values)

  # The submission flow's config types, each bound to the profile of the same type above.
  submission_config_types = concat([
    "evm.confirmations",
    "evm.gasEstimation",
    "evm.gasPricing",
    "evm.nonceAssignment",
    "evm.submission",
    "evm.transactionSerialization",
  ], keys(local.optional_profile_values))
}

resource "kaleido_platform_connector_config_type" "this" {
  for_each    = local.config_types
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = each.key
}

# ─── Chain defaults (platform catalog) ─────────────────────────────────────────

# The platform catalog's default profile values for the ecosystem and network - the values the
# console applies when it configures a connector. There are none for a chain with no ecosystem.
data "kaleido_platform_catalog_web3ecosystem_defaults" "chain" {
  count     = var.ecosystem == null ? 0 : 1
  ecosystem = var.ecosystem.name
  network   = try(var.network.name, null)
}

# The chain defaults as they were when first applied, one per config type, so a change to the catalog
# never silently changes a deployed connector. A new ecosystem or network takes a fresh copy, and a
# config type the catalog adds later is picked up when it first appears.
resource "terraform_data" "chain_default" {
  for_each         = var.track_chain_defaults ? {} : local.catalog_profile_values
  input            = each.value
  triggers_replace = [try(var.ecosystem.name, null), try(var.network.name, null)]
  lifecycle {
    ignore_changes = [input]
  }
}

locals {
  # JSON-encoded profile values, keyed by config type.
  catalog_profile_values = try(data.kaleido_platform_catalog_web3ecosystem_defaults.chain[0].config_profiles, {})
  chain_profile_values = var.track_chain_defaults ? local.catalog_profile_values : {
    for t, d in terraform_data.chain_default : t => d.output
  }

  # Each profile's value is the caller's merged into the chain default: settings the caller leaves out,
  # or null, keep the chain's value. The merge is also made against the catalog's current defaults, to
  # tell when a held default that has since changed would change a deployed profile.
  caller_profile_json = { for t, v in local.profile_values : t => v == null ? "null" : jsonencode(v) }
  profile_value_json = {
    for t, j in local.caller_profile_json : t => provider::kaleido::merge_json(lookup(local.chain_profile_values, t, "{}"), j)
  }
  current_profile_value_json = {
    for t, j in local.caller_profile_json : t => provider::kaleido::merge_json(lookup(local.catalog_profile_values, t, "{}"), j)
  }

  # Profiles whose value would change if the catalog's current defaults were taken.
  stale_chain_defaults = sort([
    for t, j in local.profile_value_json : t if local.current_profile_value_json[t] != j
  ])
}

check "chain_defaults_current" {
  assert {
    condition     = length(local.stale_chain_defaults) == 0
    error_message = "The platform catalog's chain defaults have changed since this connector was deployed, which would change the ${join(", ", local.stale_chain_defaults)} profiles. The deployed profiles keep the values they were given. To take the current defaults, set track_chain_defaults = true, or replace module.<name>.terraform_data.chain_default."
  }
}

# ─── Config profiles (one per type) ───────────────────────────────────────────

resource "kaleido_platform_connector_config_profile" "this" {
  for_each    = local.profile_values
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = each.key
  config_type = each.key
  value_json  = local.profile_value_json[each.key]
  depends_on  = [kaleido_platform_connector_config_type.this]
}

# ─── Connector flows ──────────────────────────────────────────────────────────

locals {
  # The connector flows this module deploys. To add one, add it here, add its
  # kaleido_platform_connector_flow resource below, and add it to flow_deployed_version.
  connector_flows = ["submission", "query"]
}

# The template versions the connector service stores for each flow, for "latest" and for the check
# below. On a connector's first deploy these are read during apply, once the service exists.
data "kaleido_platform_connector_template_versions" "flow" {
  for_each    = toset(local.connector_flows)
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  kind        = "connector_flow"
  name        = each.key
}

locals {
  # Each flow's version: pinned, the latest stored ("latest"), or null - held at its deployed version
  # by the provider, which deploys the latest version when the flow is first created.
  flow_version = {
    for f, d in data.kaleido_platform_connector_template_versions.flow : f => (
      lookup(var.flow_versions, f, null) == "latest" ? d.latest : lookup(var.flow_versions, f, null)
    )
  }
  # A pinned submission version as one comparable number (2026.09.0 is 202600090000), or null when the
  # flow is held or tracks latest. Terraform does not short-circuit ||, so comparisons with it must
  # handle the null themselves.
  submission_pin = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", lookup(var.flow_versions, "submission", ""))) ? sum([
    for i, p in split(".", var.flow_versions["submission"]) : tonumber(p) * pow(10000, 2 - i)
  ]) : null

  flow_deployed_version = {
    submission = kaleido_platform_connector_flow.submission.version
    query      = kaleido_platform_connector_flow.query.version
  }

  # Held flows the connector service now stores a newer version of.
  held_flow_upgrades = {
    for f, d in data.kaleido_platform_connector_template_versions.flow : f => d.latest
    if !contains(keys(var.flow_versions), f) && local.flow_deployed_version[f] != d.latest
  }
}

check "flow_versions_current" {
  assert {
    condition     = length(local.held_flow_upgrades) == 0
    error_message = "Newer connector flow versions are available: ${join(", ", [for f, v in local.held_flow_upgrades : "${f} ${local.flow_deployed_version[f]} -> ${v}"])}. Held flows stay at their deployed version. To upgrade, set flow_versions, e.g. { ${join(", ", [for f, v in local.held_flow_upgrades : "${f} = \"${v}\""])} } to pin, or \"latest\" to track."
  }
}

resource "kaleido_platform_connector_flow" "submission" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "submission"
  version     = local.flow_version["submission"]
  # Bound by ID, not name: the connector resolves a profile once, at deploy or upgrade, so a profile
  # replaced under the same name would leave the flow on the deleted one with no diff in the plan.
  config_profiles = {
    for t in local.submission_config_types : t => {
      profile_id = kaleido_platform_connector_config_profile.this[t].id
    }
  }
}

resource "kaleido_platform_connector_flow" "query" {
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "query"
  version     = local.flow_version["query"]
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

resource "kaleido_platform_connector_standard_api" "utilities" {
  count       = var.deploy_utilities_api ? 1 : 0
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  name        = "utilities"
  # Synchronous operations only, so it binds no connector flows.
  flow_type_bindings = {}
}

# ─── Standard streams ─────────────────────────────────────────────────────────

resource "kaleido_platform_connector_standard_stream" "new_blocks" {
  environment               = var.environment_id
  service                   = kaleido_platform_service.this.id
  name                      = "newBlocks"
  config_profile_name_or_id = kaleido_platform_connector_config_profile.this["evm.blockEventsConfig"].id
}
