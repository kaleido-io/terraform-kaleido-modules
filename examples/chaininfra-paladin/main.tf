# Create an environment only when an existing environment_id was not provided.
resource "kaleido_platform_environment" "env_0" {
  count = var.environment_id == "" ? 1 : 0
  name  = var.environment_name
}

locals {
  environment_id  = var.environment_id != "" ? var.environment_id : kaleido_platform_environment.env_0[0].id
  admin_node_name = "${var.node_name_prefix}-1"
}

# ─── Base ledger: Besu network + node + EVM gateway ─────────────────────────────

module "besu_network" {
  source = "../../modules/chaininfra-besu-network"

  environment_id = local.environment_id
  network_name   = var.besu_network_name
  stack_name     = var.besu_network_name
}

module "besu_node" {
  source = "../../modules/chaininfra-besu-node"

  environment_id = local.environment_id
  network_id     = module.besu_network.network_id
  stack_id       = module.besu_network.stack_id
  node_name      = "${var.besu_network_name}-node-1"
}

module "evm_gateway" {
  source = "../../modules/chaininfra-evm-gateway"

  environment_id = local.environment_id
  network_id     = module.besu_network.network_id
  stack_id       = module.besu_network.stack_id
  gateway_name   = "${var.besu_network_name}-gateway"
}

# ─── Key manager + wallet for the Paladin nodes ─────────────────────────────────

resource "kaleido_platform_runtime" "kms_0" {
  type        = "KeyManager"
  name        = "kms1"
  environment = local.environment_id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "kms_0" {
  type        = "KeyManager"
  name        = "kms1"
  environment = local.environment_id
  runtime     = kaleido_platform_runtime.kms_0.id
  config_json = jsonencode({})
}

resource "kaleido_platform_kms_wallet" "wallet_0" {
  type        = "hdwallet"
  name        = var.paladin_wallet_name
  environment = local.environment_id
  service     = kaleido_platform_service.kms_0.id
  config_json = jsonencode({})
}

# ─── Paladin network + nodes ────────────────────────────────────────────────────

module "paladin_network" {
  source = "../../modules/chaininfra-paladin-network"

  environment_id = local.environment_id
  network_name   = var.network_name

  registry_mode = "deploy"
  registry_admin = {
    identity  = var.registry_admin_identity
    node_name = local.admin_node_name
  }
}

# Node 1 is the registry admin: it deploys the registry and reads back its
# address. The remaining nodes are auto-discovered/registered by the operator.
module "paladin_node" {
  source = "../../modules/chaininfra-paladin-node"
  count  = var.node_count

  environment_id          = local.environment_id
  network_id              = module.paladin_network.network_id
  stack_id                = module.paladin_network.stack_id
  node_name               = "${var.node_name_prefix}-${count.index + 1}"
  registry_admin_identity = var.registry_admin_identity
  key_manager_service_id  = kaleido_platform_service.kms_0.id

  base_ledger = {
    type               = "local"
    gateway_service_id = module.evm_gateway.service_id
  }

  wallets = {
    kms_key_store = kaleido_platform_kms_wallet.wallet_0.name
  }

  domains = var.domains

  hostname              = var.publish_hostnames ? "${var.node_name_prefix}-${count.index + 1}" : null
  read_registry_address = count.index == 0
}

# ─── Outputs ────────────────────────────────────────────────────────────────────

output "network_id" {
  value = module.paladin_network.network_id
}

output "stack_id" {
  value = module.paladin_network.stack_id
}

output "node_service_ids" {
  value = module.paladin_node[*].service_id
}

output "node_endpoints" {
  value = module.paladin_node[*].endpoints
}

output "registry_address" {
  value = module.paladin_node[0].registry_address
}
