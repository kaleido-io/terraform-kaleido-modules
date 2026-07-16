locals {
  stack_name = var.stack_name != null ? var.stack_name : var.network_name

  evm_registry = merge(
    {
      registryContract = var.registry_mode
      admin = {
        identity = var.registry_node
        nodeName = var.registry_node
      }
    },
    var.registry_mode == "existing" ? {
      existingContract = { address = var.existing_registry_address }
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
