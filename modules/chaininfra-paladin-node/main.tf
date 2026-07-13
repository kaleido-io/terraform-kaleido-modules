# ─── PaladinNode runtime + service ──────────────────────────────────────────────

locals {
  # In deploy mode the registry node submits the registry deploy transaction, so it
  # is the only node whose registry address read will ever complete.
  is_registry_node = (
    var.network_registry != null
    && var.network_registry.mode == "deploy"
    && var.network_registry.registry_node == var.node_name
  )

  base_ledger = merge(
    { type = var.base_ledger.type },
    var.base_ledger.type == "local" ? {
      local = merge(
        var.base_ledger.gateway_service_id != null ? { gateway = { id = var.base_ledger.gateway_service_id } } : {},
        var.base_ledger.besu_node_service_id != null ? { node = { id = var.base_ledger.besu_node_service_id } } : {},
      )
    } : {},
    var.base_ledger.type == "endpoint" ? {
      endpoint = merge(
        {
          jsonrpc = var.base_ledger.jsonrpc_url
          ws      = var.base_ledger.ws_url
        },
        # Credentials are stored as the `jsonRpcAuth` cred set and referenced by name.
        var.base_ledger.auth != null ? { auth = { credSetRef = "jsonRpcAuth" } } : {},
      )
    } : {},
  )

  wallets = merge(
    { kmsKeyStore = var.wallets.kms_key_store },
    var.wallets.kms_folder_path != null ? { kmsFolderPath = var.wallets.kms_folder_path } : {},
    var.wallets.zeto_wallet_prefix != null ? { zetoWalletPrefix = var.wallets.zeto_wallet_prefix } : {},
    # The seed is stored as the `zetoWalletSeed` cred set and referenced by name.
    var.wallets.zeto_wallet_seed != null ? { zetoWalletSeed = { credSetRef = "zetoWalletSeed" } } : {},
  )

  base_config = merge(
    length(var.domains) > 0 ? { domains = var.domains } : {},
    var.base_config,
  )

  service_config = merge(
    {
      network            = { id = var.network_id }
      keyManager         = { id = var.key_manager_service_id }
      baseLedgerEndpoint = local.base_ledger
      # registryAdminIdentity is required by the PaladinNodeService schema but is not
      # consumed by the platform (the network CR drives registry operations, and the
      # registry is rootless). Send the node's own name.
      registryAdminIdentity = var.node_name
      wallets               = local.wallets
    },
    # baseConfig is a JSON string within the config,
    length(local.base_config) > 0 ? { baseConfig = jsonencode(local.base_config) } : {},
  )
}

resource "kaleido_platform_runtime" "this" {
  type        = "PaladinNodeRuntime"
  name        = var.node_name
  environment = var.environment_id
  stack_id    = var.stack_id
  config_json = jsonencode({})

  size         = var.runtime_size
  zone         = var.runtime_zone
  storage_size = var.storage_size
  storage_type = var.storage_type
}

resource "kaleido_platform_service" "this" {
  type        = "PaladinNodeService"
  name        = var.node_name
  environment = var.environment_id
  stack_id    = var.stack_id
  runtime     = kaleido_platform_runtime.this.id
  config_json = jsonencode(local.service_config)
  # Nodes can't reach Ready until the registry node deploys the registry and
  # registers them, so blocking here risks exhausting Terraform's default
  # parallelism when creating many nodes in one apply.
  wait_for_ready = false

  cred_sets = merge(
    var.base_ledger.auth != null ? {
      jsonRpcAuth = {
        type = "basic_auth"
        basic_auth = {
          username = var.base_ledger.auth.username
          password = var.base_ledger.auth.password
        }
      }
    } : {},
    var.wallets.zeto_wallet_seed != null ? {
      zetoWalletSeed = {
        type = "key"
        key  = { value = var.wallets.zeto_wallet_seed }
      }
    } : {},
  )
}

resource "kaleido_platform_hostname" "this" {
  count       = var.hostname != null ? 1 : 0
  name        = var.node_name
  environment = var.environment_id
  service     = kaleido_platform_service.this.id
  hostname    = var.hostname
  endpoints   = ["jsonrpc", "jsonrpcws"]
  mtls        = false
}

data "kaleido_platform_paladin_evm_registry" "this" {
  count       = local.is_registry_node ? 1 : 0
  environment = var.environment_id
  network     = var.network_id
  depends_on  = [kaleido_platform_service.this]
}
