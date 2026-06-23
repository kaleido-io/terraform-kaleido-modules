# --- Canton Super Validator Node ─────────────────────────────────────────────────────────────────

locals {
  folder = var.kms_wallet_folder != null ? var.kms_wallet_folder : var.node_name

  config = merge(
    {
      network = { id = var.network_id }
      defaultParty = var.default_party
      kms = {
        keyManager = { id = var.kms_id }
        wallet = var.kms_wallet_name
        folder = local.folder
        keySpec = var.kms_key_spec
      }
    },
    var.node_key != null ? { nodeKey = { credSetRef = "nodeKey" } } : {},
  )
}

resource "kaleido_platform_runtime" "this" {
  type        = "CantonSuperValidatorNode"
  name        = var.node_name
  environment = var.environment_id
  stack_id = var.stack_id
  size = var.runtime_size
  zone = var.zone
  sub_zone = var.subzone
  storage_size = var.storage_size
  storage_type = var.storage_type
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "this" {
  type = "CantonSuperValidatorNode"
  name = var.node_name
  stack_id = var.stack_id
  environment = var.environment_id
  runtime = kaleido_platform_runtime.this.id
  config_json = jsonencode(local.config)

  cred_sets = var.node_key != null ? {
    nodeKey = {
      type = "credset"
      value = var.node_key
    }
  } : {}
}

# ─── hostnames ───────────────────────────────────────────────────────────────────────────────

resource "kaleido_platform_hostname" "ledger" {
  name = "${var.hostname_prefix}-ledger"
  environment = var.environment_id
  service = kaleido_platform_service.this.id
  hostname = "${var.hostname_prefix}-ledger"
  endpoints = ["ledger"]
  mtls = false
  count = var.hostname_prefix != null ? 1 : 0
}

resource "kaleido_platform_hostname" "admin" {
  name = "${var.hostname_prefix}-admin"
  environment = var.environment_id
  service = kaleido_platform_service.this.id
  hostname = "${var.hostname_prefix}-admin"
  endpoints = ["admin"]
  mtls = false
  count = var.hostname_prefix != null ? 1 : 0
}