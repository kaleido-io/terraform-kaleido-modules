# ─── PaladinNode runtime + service ──────────────────────────────────────────────

locals {
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

  # db, log, blockchain, rpcServer, transports, registries, keyManager, and
  # debugServer are platform-managed — the operator overwrites them if set here.
  base_config = merge(
    length(var.domains) > 0 ? { domains = var.domains } : {},
    var.base_config,
  )

  service_config = merge(
    {
      network               = { id = var.network_id }
      keyManager            = { id = var.key_manager_service_id }
      baseLedgerEndpoint    = local.base_ledger
      registryAdminIdentity = var.registry_admin_identity
      wallets               = local.wallets
    },
    # baseConfig is a JSON string within the config (x-kld-type-hint=jsonstring),
    # so it is encoded separately and double-encoded overall.
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

# Deploy-mode registry read-back: the address only exists after the admin node
# has deployed the registry, so the data source lives here rather than in the
# network module.
data "kaleido_platform_paladin_evm_registry" "this" {
  count       = var.read_registry_address ? 1 : 0
  environment = var.environment_id
  network     = var.network_id
  depends_on  = [kaleido_platform_service.this]
}
