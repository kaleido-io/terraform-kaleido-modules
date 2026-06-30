# --- Canton Synchronizer Node ───────────────────────────────────────────────────────────────────

locals {
  folder = var.kms_wallet_folder != null ? var.kms_wallet_folder : var.node_name
}

resource "kaleido_platform_runtime" "this" {
  type        = "CantonSynchronizerNode"
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
  type = "CantonSynchronizerNode"
  name = var.node_name
  stack_id = var.stack_id
  environment = var.environment_id
  runtime = kaleido_platform_runtime.this.id
  config_json = jsonencode({
    network = {
      id = var.network_id
    }
    kms = {
      keyManager = {
        id = var.kms_id
      }
      wallet = var.kms_wallet_name
      folder = local.folder
      keySpec = var.kms_key_spec
    }
  })
}

# ─── hostnames ───────────────────────────────────────────────────────────────────────────────

resource "kaleido_platform_hostname" "sequencer" {
  name = "${var.hostname_prefix}-sequencer"
  environment = var.environment_id
  service = kaleido_platform_service.this.id
  hostname = "${var.hostname_prefix}-sequencer"
  endpoints = ["sequencer"]
  mtls = false
  count = var.hostname_prefix != null ? 1 : 0
}

resource "kaleido_platform_hostname" "admin" {
  name = "${var.hostname_prefix}-admin"
  environment = var.environment_id
  service = kaleido_platform_service.this.id
  hostname = "${var.hostname_prefix}-admin"
  endpoints = ["sequencer-admin"]
  mtls = false
  count = var.hostname_prefix != null ? 1 : 0
}

resource "kaleido_platform_hostname" "mediator" {
  name = "${var.hostname_prefix}-mediator"
  environment = var.environment_id
  service = kaleido_platform_service.this.id
  hostname = "${var.hostname_prefix}-mediator"
  endpoints = ["mediator"]
  mtls = false
  count = var.hostname_prefix != null ? 1 : 0
}