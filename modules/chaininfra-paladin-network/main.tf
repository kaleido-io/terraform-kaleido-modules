# ─── PaladinNetwork + chain-infrastructure stack ────────────────────────────────

locals {
  stack_name = var.stack_name != null ? var.stack_name : var.network_name

  evm_registry = merge(
    { registryContract = var.registry_mode },
    var.registry_mode == "existing" ? {
      existingContract = { address = var.existing_registry_address }
    } : {},
    var.registry_mode == "deploy" ? {
      admin = {
        identity = var.registry_admin.identity
        nodeName = var.registry_admin.node_name
      }
    } : {},
  )
}

resource "kaleido_platform_network" "this" {
  type        = "PaladinNetwork"
  name        = var.network_name
  environment = var.environment_id

  config_json = jsonencode({
    type        = "evmRegistry"
    evmRegistry = local.evm_registry
  })
}

resource "kaleido_platform_stack" "this" {
  environment = var.environment_id
  name        = local.stack_name
  type        = "chain_infrastructure"
  sub_type    = "PaladinStack"
  network_id  = kaleido_platform_network.this.id
}
