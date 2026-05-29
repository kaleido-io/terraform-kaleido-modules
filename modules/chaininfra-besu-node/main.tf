# ─── BesuNode runtime + service ─────────────────────────────────────────────────

locals {
  node_config = merge(
    {
      network           = { id = var.network_id }
      routable          = var.routable
      mode              = var.mode
      signer            = var.signer
      syncMode          = var.sync_mode
      logLevel          = var.log_level
      dataStorageFormat = var.data_storage_format
      apisEnabled       = var.apis_enabled
      customBesuArgs    = var.custom_besu_args
      gasPrice          = var.gas_price
    },
    var.target_gas_limit != null ? { targetGasLimit = var.target_gas_limit } : {},
    # A genesis supplied inline is stored as the `genesis` file set and referenced by name.
    var.genesis_json != null ? { genesis = { fileSetRef = "genesis" } } : {},
    # A user-provided node key is stored as the `nodeKey` cred set and referenced by name.
    var.node_key != null ? { nodeKey = { credSetRef = "nodeKey" } } : {},
  )
}

resource "kaleido_platform_runtime" "this" {
  type        = "BesuNode"
  name        = var.node_name
  environment = var.environment_id
  stack_id    = var.stack_id
  config_json = jsonencode({})

  size         = var.runtime_size
  zone         = var.zone
  storage_size = var.storage_size
  storage_type = var.storage_type
}

resource "kaleido_platform_service" "this" {
  type        = "BesuNode"
  name        = var.node_name
  environment = var.environment_id
  stack_id    = var.stack_id
  runtime     = kaleido_platform_runtime.this.id
  config_json = jsonencode(local.node_config)

  file_sets = var.genesis_json != null ? {
    genesis = {
      files = {
        "genesis.json" = {
          type = "json"
          data = { text = var.genesis_json }
        }
      }
    }
  } : {}

  cred_sets = var.node_key != null ? {
    nodeKey = {
      type = "key"
      key  = { value = var.node_key }
    }
  } : {}
}
