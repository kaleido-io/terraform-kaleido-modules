# ─── Account 2 ───────────────────────────────────────────────────────────────

data "kaleido_platform_account" "account_2" {
    provider = kaleido.account_2
}

resource "kaleido_platform_environment" "account_2_env" {
  provider = kaleido.account_2
  name = var.environment_name
}

resource "kaleido_platform_runtime" "account_2_kms" {
    provider = kaleido.account_2
    type = "KeyManager"
    name = "kms"
    environment = kaleido_platform_environment.account_2_env.id
    config_json = jsonencode({})
}

resource "kaleido_platform_service" "account_2_kms" {
    provider = kaleido.account_2
    type = "KeyManager"
    name = "kms"
    environment = kaleido_platform_environment.account_2_env.id
    runtime = kaleido_platform_runtime.account_2_kms.id
    config_json = jsonencode({})
}

resource "kaleido_platform_kms_wallet" "account_2_kms_wallet" {
    provider = kaleido.account_2
    type = var.kms_wallet_type
    name = "canton"
    environment = kaleido_platform_environment.account_2_env.id
    service = kaleido_platform_service.account_2_kms.id
    config_json = jsonencode({})
}

module "chaininfra-canton-synchronizer-network-account-2" {
  source = "../../modules/chaininfra-canton-synchronizer-network"
  providers = {
    kaleido = kaleido.account_2
  }
  environment_id = kaleido_platform_environment.account_2_env.id
  network_name = var.synchronizer_network_name
  stack_enabled = true
  init_mode = "manual"
}

module "chaininfra-canton-participant-node-account-2-bob" {
  source = "../../modules/chaininfra-canton-participant-node"
  providers = {
    kaleido = kaleido.account_2
  }
  environment_id = kaleido_platform_environment.account_2_env.id
  stack_id = module.chaininfra-canton-synchronizer-network-account-2.stack_id
  default_party = "bob"
  kms_key_spec = var.kms_key_spec

  synchronizer_network_ids = [module.chaininfra-canton-synchronizer-network-account-2.network_id]
  kms_id = kaleido_platform_service.account_2_kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.account_2_kms_wallet.name
}

## ─── Network connector ───────────────────────────────────────────────────────────────

resource "kaleido_network_connector" "chaininfra-canton-sync-account-2-connector" {
  provider = kaleido.account_2
  type = "Platform"
  name = "chaininfra-canton-sync-account-2-connector"
  environment = kaleido_platform_environment.account_2_env.id
  network = module.chaininfra-canton-synchronizer-network-account-2.network_id
  zone = var.platform_connector_zone

  platform_acceptor = {
    target_account_id = data.kaleido_platform_account.account_1.account_id
    target_environment_id = kaleido_platform_environment.account_1_env.id
    target_network_id = module.chaininfra-canton-synchronizer-network-account-1.network_id
    target_connector_id = kaleido_network_connector.chaininfra-canton-sync-account-1-connector.id
  }
}