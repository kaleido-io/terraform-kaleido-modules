# --- Canton Synchronizer Network + chain-infrastructure stack ───────────────────────────────────

locals {
  config = merge(
    {
      type = var.external_sequencer_endpoint != null ? "Remote" : "Local"
    },
    var.external_sequencer_endpoint != null ? {
      sequencer = var.external_sequencer_endpoint
    } : {}
  )

  stack_name = var.stack_name != null ? var.stack_name : var.network_name
}

resource "kaleido_platform_network" "this" {
  type        = "CantonSynchronizer"
  name        = var.network_name
  environment = var.environment_id
  init_mode   = "automated"
  config_json = jsonencode(local.config)
}

// Stack is optional, since canton participant node created in 
// another stack might also connect to this network
resource "kaleido_platform_stack" "this" {
  environment = var.environment_id
  name        = local.stack_name
  type        = "chain_infrastructure"
  sub_type = "CantonStack"
  network_id  = kaleido_platform_network.this.id
  count = var.stack_enabled ? 1 : 0 
}