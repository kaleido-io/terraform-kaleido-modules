# ─── Account 1 ───────────────────────────────────────────────────────────────

data "kaleido_platform_account" "account_1" {
    provider = kaleido.account_1
}

resource "kaleido_platform_environment" "account_1_env" {
  provider = kaleido.account_1
  name = var.environment_name
}

resource "kaleido_platform_runtime" "account_1_kms" {
    provider = kaleido.account_1
    type = "KeyManager"
    name = "kms"
    environment = kaleido_platform_environment.account_1_env.id
    config_json = jsonencode({})
}

resource "kaleido_platform_service" "account_1_kms" {
    provider = kaleido.account_1
    type = "KeyManager"
    name = "kms"
    environment = kaleido_platform_environment.account_1_env.id
    runtime = kaleido_platform_runtime.account_1_kms.id
    config_json = jsonencode({})
}

resource "kaleido_platform_kms_wallet" "account_1_kms_wallet" {
    provider = kaleido.account_1
    type = var.kms_wallet_type
    name = "canton"
    environment = kaleido_platform_environment.account_1_env.id
    service = kaleido_platform_service.account_1_kms.id
    config_json = jsonencode({})
}

## ─── Canton synchronizer network ───────────────────────────────────────────────────────────────

module "chaininfra-canton-synchronizer-network-account-1" {
  source = "../../modules/chaininfra-canton-synchronizer-network"
  providers = {
    kaleido = kaleido.account_1
  }
  environment_id = kaleido_platform_environment.account_1_env.id
  network_name = var.synchronizer_network_name
  stack_enabled = true
}

module "chaininfra-canton-synchronizer-node-account-1" {
  source = "../../modules/chaininfra-canton-synchronizer-node"
  providers = {
    kaleido = kaleido.account_1
  }
  environment_id = kaleido_platform_environment.account_1_env.id
  network_id = module.chaininfra-canton-synchronizer-network-account-1.network_id
  stack_id = module.chaininfra-canton-synchronizer-network-account-1.stack_id
  kms_id = kaleido_platform_service.account_1_kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.account_1_kms_wallet.name
}

## ─── Canton participant node ───────────────────────────────────────────────────────────────

module "chaininfra-canton-participant-node-account-1-alice" {
  source = "../../modules/chaininfra-canton-participant-node"
  providers = {
    kaleido = kaleido.account_1
  }
  environment_id = kaleido_platform_environment.account_1_env.id
  stack_id = module.chaininfra-canton-synchronizer-network-account-1.stack_id
  default_party = "alice"
  kms_key_spec = var.kms_key_spec

  synchronizer_network_ids = [module.chaininfra-canton-synchronizer-network-account-1.network_id]
  kms_id = kaleido_platform_service.account_1_kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.account_1_kms_wallet.name
}

## ─── Network connector ───────────────────────────────────────────────────────────────

resource "kaleido_network_connector" "chaininfra-canton-sync-account-1-connector" {
  provider = kaleido.account_1
  type = "Platform"
  name = "chaininfra-canton-sync-account-1-connector"
  environment = kaleido_platform_environment.account_1_env.id
  network = module.chaininfra-canton-synchronizer-network-account-1.network_id
  zone = var.platform_connector_zone

  platform_requestor = {
    target_account_id = data.kaleido_platform_account.account_2.account_id
    target_environment_id = kaleido_platform_environment.account_2_env.id
    target_network_id = module.chaininfra-canton-synchronizer-network-account-2.network_id
  }
}