resource "kaleido_platform_environment" "env" {
  name = var.environment_name
}

resource "kaleido_platform_runtime" "kms" {
    type = "KeyManager"
    name = "kms"
    environment = kaleido_platform_environment.env.id
    config_json = jsonencode({})
}

resource "kaleido_platform_service" "kms" {
    type = "KeyManager"
    name = "kms"
    environment = kaleido_platform_environment.env.id
    runtime = kaleido_platform_runtime.kms.id
    config_json = jsonencode({})
}

resource "kaleido_platform_kms_wallet" "kms_wallet" {
    type = var.kms_wallet_type
    name = "canton-sandbox"
    environment = kaleido_platform_environment.env.id
    service = kaleido_platform_service.kms.id
    config_json = jsonencode({})
}

# ─── Canton validator network ───────────────────────────────────────────────────────────────

module "chaininfra-canton-validator-network" {
  source = "../../modules/chaininfra-canton-validator-network"

  environment_id = kaleido_platform_environment.env.id
  network_type = "Sandbox"
}

module "chaininfra-canton-super-validator-node-alice" {
  source = "../../modules/chaininfra-canton-super-validator-node"

  environment_id = kaleido_platform_environment.env.id
  network_id = module.chaininfra-canton-validator-network.network_id
  stack_id = module.chaininfra-canton-validator-network.stack_id
  default_party = "alice"
  kms_id = kaleido_platform_service.kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.kms_wallet.name
  runtime_size = "Medium"
}

# ─── Canton participant node ───────────────────────────────────────────────────────────────

module "chaininfra-canton-participant-node-bob" {
  source = "../../modules/chaininfra-canton-participant-node"

  environment_id = kaleido_platform_environment.env.id
  stack_id = module.chaininfra-canton-validator-network.stack_id
  default_party = "bob"
  kms_key_spec = var.kms_key_spec
  
  validator_network_id = module.chaininfra-canton-validator-network.network_id
  kms_id = kaleido_platform_service.kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.kms_wallet.name
}