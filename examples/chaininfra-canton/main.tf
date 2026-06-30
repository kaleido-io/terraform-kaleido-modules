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
    name = "canton-${var.network_type}"
    environment = kaleido_platform_environment.env.id
    service = kaleido_platform_service.kms.id
    config_json = jsonencode({})
}

# ─── Canton validator network ───────────────────────────────────────────────────────────────

module "chaininfra-canton-validator-network" {
  source = "../../modules/chaininfra-canton-validator-network"

  environment_id = kaleido_platform_environment.env.id
  network_type = var.network_type
  sponsor_super_validator = var.network_type != "Sandbox" ? var.sponsor_super_validator : null
  count = var.validator_network_enabled ? 1 : 0
}

module "chaininfra-canton-super-validator-node" {
  source = "../../modules/chaininfra-canton-super-validator-node"

  environment_id = kaleido_platform_environment.env.id
  network_id = module.chaininfra-canton-validator-network[0].network_id
  stack_id = module.chaininfra-canton-validator-network[0].stack_id
  default_party = "${var.network_type}-sv"
  kms_id = kaleido_platform_service.kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.kms_wallet.name
  runtime_size = "Large"
  count = var.network_type == "Sandbox" && var.validator_network_enabled ? 1 : 0
}

# ─── Canton synchronizer network ───────────────────────────────────────────────────────────────

locals {
  synchronizer_network_with_stack = !var.validator_network_enabled

  synchronizer_network_stack_id = local.synchronizer_network_with_stack ? module.chaininfra-canton-synchronizer-network[0].stack_id : null
}

module "chaininfra-canton-synchronizer-network" {
  source = "../../modules/chaininfra-canton-synchronizer-network"
  environment_id = kaleido_platform_environment.env.id
  network_name = var.synchronizer_network_name
  stack_enabled = local.synchronizer_network_with_stack
  count = var.synchronizer_network_enabled ? 1 : 0
}

module "chaininfra-canton-synchronizer-node" {
  source = "../../modules/chaininfra-canton-synchronizer-node"
  environment_id = kaleido_platform_environment.env.id
  network_id = module.chaininfra-canton-synchronizer-network[0].network_id
  stack_id = local.synchronizer_network_stack_id
  kms_id = kaleido_platform_service.kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.kms_wallet.name
  count = var.synchronizer_network_enabled ? 1 : 0
}

# ─── Canton participant node ───────────────────────────────────────────────────────────────

locals {
  stack_id = local.synchronizer_network_with_stack ? module.chaininfra-canton-synchronizer-network[0].stack_id : module.chaininfra-canton-validator-network[0].stack_id
}

module "chaininfra-canton-participant-node" {
  source = "../../modules/chaininfra-canton-participant-node"

  environment_id = kaleido_platform_environment.env.id
  stack_id = local.stack_id
  default_party = "${var.network_type}-participant"
  kms_wallet_folder = "canton-${var.network_type}"
  kms_key_spec = "secp256r1"
  
  onboarding_secret = var.network_type == "Testnet" || var.network_type == "Mainnet" ? file(var.onboarding_secret_file) : null

  validator_network_id = module.chaininfra-canton-validator-network[0].network_id
  synchronizer_network_ids = var.synchronizer_network_enabled ? [module.chaininfra-canton-synchronizer-network[0].network_id] : []
  kms_id = kaleido_platform_service.kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.kms_wallet.name
}