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

  lifecycle {
    # The registry deploy transaction is signed by the admin node's
    # registryAdminIdentity — if it differs from the identity named in the
    # network's registry_admin, the registry is administered by the wrong key.
    precondition {
      condition = (
        var.network_registry == null ||
        try(var.network_registry.admin.node_name, null) != var.node_name ||
        var.registry_admin_identity == var.network_registry.admin.identity
      )
      error_message = "This node is the network's registry admin (node_name matches network_registry.admin.node_name), but registry_admin_identity does not match network_registry.admin.identity. The registry deploy transaction would be signed by a different identity than the network expects to administer the registry."
    }
  }
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
  count       = var.read_registry_address ? 1 : 0
  environment = var.environment_id
  network     = var.network_id
  depends_on  = [kaleido_platform_service.this]

  lifecycle {
    precondition {
      condition     = var.network_registry == null || var.network_registry.mode == "deploy"
      error_message = "read_registry_address = true but network_registry.mode is not 'deploy'. There is no registry deploy transaction to wait for, so the read would poll forever. In existing mode the registry address is already known — consume it from the network configuration instead."
    }
    precondition {
      condition     = var.network_registry == null || try(var.network_registry.admin.node_name, null) == var.node_name
      error_message = "read_registry_address = true on a node whose node_name does not match network_registry.admin.node_name. The registry deploy transaction is only submitted via the admin node — set read_registry_address = true on that node."
    }
  }
}
