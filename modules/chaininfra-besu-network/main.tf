# ─── BesuNetwork + chain-infrastructure stack ───────────────────────────────────

locals {
  # Supplying an inline genesis takes over initialization: the platform stops
  # so callers can own and upgrade the genesis over time.
  use_inline_genesis = var.genesis_json != null

  # Derive the name from a content hash so any edit to `genesis_json` rolls the
  # file set (and re-inits) automatically — callers only ever pass updated `genesis_json`.
  genesis_file_set = local.use_inline_genesis ? "genesis-${substr(sha256(var.genesis_json), 0, 12)}" : null

  bootstrap_options = merge(
    {
      qbft             = {
        for k, v in var.qbft : k => v
        if v != null
      }
      eipBlockConfig   = var.eip_block_config
      blockConfigFlags = var.block_config_flags
    },
    length(var.initial_validators) > 0 ? { initialValidators = var.initial_validators } : {},
    length(var.initial_balances) > 0 ? { initialBalances = var.initial_balances } : {},
    var.target_gas_limit != null ? { targetGasLimit = var.target_gas_limit } : {},
  )

  network_config = merge(
    !local.use_inline_genesis && var.chain_id != null ? { chainID = var.chain_id } : {},
    { bootstrapOptions = local.bootstrap_options },
  )
}

resource "kaleido_platform_network" "this" {
  type        = "Besu"
  name        = var.network_name
  environment = var.environment_id
  init_mode   = local.use_inline_genesis ? "manual" : var.init_mode
  config_json = jsonencode(local.network_config)

  file_sets = local.use_inline_genesis ? {
    (local.genesis_file_set) = {
      files = {
        "genesis.json" = {
          type = "json"
          data = { text = var.genesis_json }
        }
      }
    }
  } : {}
  init_files = local.genesis_file_set
}

resource "kaleido_platform_stack" "this" {
  environment = var.environment_id
  name        = var.stack_name
  type        = "chain_infrastructure"
  network_id  = kaleido_platform_network.this.id
}
