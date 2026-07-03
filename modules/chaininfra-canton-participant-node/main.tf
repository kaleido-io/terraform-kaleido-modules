# --- Canton Synchronizer Network + chain-infrastructure stack ───────────────────────────────────

locals {
  node_name       = var.node_name != null ? var.node_name : "participant-${var.default_party}"
  folder          = var.kms_wallet_folder != null ? var.kms_wallet_folder : local.node_name
  hostname_prefix = var.hostname_prefix != null ? var.hostname_prefix : local.node_name

  synchronizer_networks = length(var.synchronizer_network_ids) > 0 ? [
    for id in var.synchronizer_network_ids : {
      network = {
        id = id
      }
    }
  ] : []

  config = merge(
    {
      defaultParty = var.default_party
    },
    {
      kms = {
        keyManager = {
          id = var.kms_id
        }
        wallet  = var.kms_wallet_name
        folder  = local.folder
        keySpec = var.kms_key_spec
      }
    },
    var.validator_network_id != null ? {
      validatorNetwork = {
        id = var.validator_network_id
      }
    } : {},
    length(local.synchronizer_networks) > 0 ? {
      synchronizerNetworks = local.synchronizer_networks
    } : {},
    var.onboarding_secret != null ? {
      onboardingSecret = var.onboarding_secret
    } : {}
  )
}

resource "kaleido_platform_runtime" "this" {
  type         = "CantonParticipantNode"
  name         = local.node_name
  environment  = var.environment_id
  stack_id     = var.stack_id
  size         = var.runtime_size
  zone         = var.zone
  sub_zone     = var.subzone
  storage_size = var.storage_size
  storage_type = var.storage_type
  config_json  = jsonencode({})
}

resource "kaleido_platform_service" "this" {
  type        = "CantonParticipantNode"
  name        = local.node_name
  stack_id    = var.stack_id
  environment = var.environment_id
  runtime     = kaleido_platform_runtime.this.id
  config_json = jsonencode(local.config)
}

# ─── hostnames ───────────────────────────────────────────────────────────────────────────────

resource "kaleido_platform_hostname" "ledger" {
  name        = "${local.hostname_prefix}-ledger"
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  hostname    = "${local.hostname_prefix}-ledger"
  endpoints   = ["ledger"]
  mtls        = false
}

resource "kaleido_platform_hostname" "admin" {
  name        = "${local.hostname_prefix}-admin"
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  hostname    = "${local.hostname_prefix}-admin"
  endpoints   = ["admin"]
  mtls        = false
}

resource "kaleido_platform_hostname" "http" {
  name        = "${local.hostname_prefix}-http"
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  hostname    = local.hostname_prefix
  endpoints   = ["http-ledger", "node", "validator"]
  mtls        = false
}