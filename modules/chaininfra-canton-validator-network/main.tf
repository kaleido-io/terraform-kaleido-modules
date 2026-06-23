# --- Canton Synchronizer Network + chain-infrastructure stack ───────────────────────────────────

locals {
  
  config = merge(
    {
      type = var.network_type
    },
    var.network_type == "Sandbox" ? {
      sandbox = {
        type = "Local"
      }
    } : {
      global = {
        type = var.network_type
        sponsorSuperValidator = var.sponsor_super_validator
      }
    },
  )
}

locals {
  network_name = var.network_name != null ? var.network_name : var.network_type
  stack_name = var.stack_name != null ? var.stack_name : var.network_type
}

resource "kaleido_platform_network" "this" {
  type        = "CantonValidator"
  name        = local.network_name
  environment = var.environment_id
  init_mode   = "automated"
  config_json = jsonencode(local.config)
}

resource "kaleido_platform_stack" "this" {
  environment = var.environment_id
  name        = local.stack_name
  type        = "chain_infrastructure"
  sub_type = "CantonStack"
  network_id  = kaleido_platform_network.this.id
}