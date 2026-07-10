resource "kaleido_platform_environment" "env_0" {
  count = var.environment_id == "" ? 1 : 0
  name  = var.environment_name
}

locals {
  environment_id  = var.environment_id != "" ? var.environment_id : kaleido_platform_environment.env_0[0].id
  admin_node_name = "${var.node_name_prefix}-1"
}

# Base Ledger

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
  signer         = true
}

module "evm_gateway" {
  source = "../../modules/chaininfra-evm-gateway"

  environment_id = local.environment_id
  network_id     = module.besu_network.network_id
  stack_id       = module.besu_network.stack_id
  gateway_name   = "${var.besu_network_name}-gateway"
}

# Key Management

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

# Deployer key for the domain factories — the signer becomes the factory owner,
# so it should not be a node wallet key.
resource "kaleido_platform_kms_key" "domain_deployer" {
  name        = "domain-deployer"
  environment = local.environment_id
  service     = kaleido_platform_service.kms_0.id
  wallet      = kaleido_platform_kms_wallet.wallet_0.name
}

# Contract + Transaction Management

resource "kaleido_platform_runtime" "cms_0" {
  type        = "ContractManager"
  name        = "contracts1"
  environment = local.environment_id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "cms_0" {
  type        = "ContractManager"
  name        = "contracts1"
  environment = local.environment_id
  runtime     = kaleido_platform_runtime.cms_0.id
  config_json = jsonencode({})
}

resource "kaleido_platform_runtime" "txm_0" {
  type        = "TransactionManager"
  name        = "txm1"
  environment = local.environment_id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "txm_0" {
  type        = "TransactionManager"
  name        = "txm1"
  environment = local.environment_id
  runtime     = kaleido_platform_runtime.txm_0.id
  config_json = jsonencode({
    keyManager = { id = kaleido_platform_service.kms_0.id }
    type       = "evm"
    evm = {
      confirmations = { required = 0 }
      connector = {
        evmGateway = { id = module.evm_gateway.service_id }
      }
    }
  })
}

# Paladin Domains

module "noto" {
  source = "../../modules/chaininfra-paladin-noto"

  paladin_repo          = var.paladin_repo
  paladin_ref           = var.paladin_ref
  environment_id        = local.environment_id
  contracts_service_id  = kaleido_platform_service.cms_0.id
  txnmanager_service_id = kaleido_platform_service.txm_0.id

  signing_key_address = var.signing_key_uri != null ? null : coalesce(var.signing_key_address, kaleido_platform_kms_key.domain_deployer.address)
  signing_key_uri     = var.signing_key_uri

  depends_on = [module.besu_node]
}

module "pente" {
  source = "../../modules/chaininfra-paladin-pente"

  paladin_repo          = var.paladin_repo
  paladin_ref           = var.paladin_ref
  environment_id        = local.environment_id
  contracts_service_id  = kaleido_platform_service.cms_0.id
  txnmanager_service_id = kaleido_platform_service.txm_0.id

  signing_key_address = var.signing_key_uri != null ? null : coalesce(var.signing_key_address, kaleido_platform_kms_key.domain_deployer.address)
  signing_key_uri     = var.signing_key_uri

  # Deploy one domain at a time — both use the same signing key and TransactionManager.
  depends_on = [module.noto]
}

locals {
  domains = merge(module.noto.domain, module.pente.domain, var.domains)
}

# Paladin Network + Nodes

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

module "paladin_admin_node" {
  source = "../../modules/chaininfra-paladin-node"

  environment_id          = local.environment_id
  network_id              = module.paladin_network.network_id
  stack_id                = module.paladin_network.stack_id
  node_name               = local.admin_node_name
  registry_admin_identity = var.registry_admin_identity
  key_manager_service_id  = kaleido_platform_service.kms_0.id

  base_ledger = {
    type               = "local"
    gateway_service_id = module.evm_gateway.service_id
  }

  wallets = {
    kms_key_store   = kaleido_platform_kms_wallet.wallet_0.name
    kms_folder_path = local.admin_node_name
  }

  domains = local.domains

  hostname              = var.publish_hostnames ? local.admin_node_name : null
  read_registry_address = true
  network_registry      = module.paladin_network.registry

  depends_on = [module.besu_node]
}

# Joiner nodes wait on the admin node, which deploys the registry.
module "paladin_joiner_node" {
  source = "../../modules/chaininfra-paladin-node"
  count  = var.node_count - 1

  environment_id          = local.environment_id
  network_id              = module.paladin_network.network_id
  stack_id                = module.paladin_network.stack_id
  node_name               = "${var.node_name_prefix}-${count.index + 2}"
  registry_admin_identity = var.registry_admin_identity
  key_manager_service_id  = kaleido_platform_service.kms_0.id

  base_ledger = {
    type               = "local"
    gateway_service_id = module.evm_gateway.service_id
  }

  wallets = {
    kms_key_store   = kaleido_platform_kms_wallet.wallet_0.name
    kms_folder_path = "${var.node_name_prefix}-${count.index + 2}"
  }

  domains = local.domains

  hostname         = var.publish_hostnames ? "${var.node_name_prefix}-${count.index + 2}" : null
  network_registry = module.paladin_network.registry

  depends_on = [module.paladin_admin_node]
}

# Outputs

output "network_id" {
  value = module.paladin_network.network_id
}

output "stack_id" {
  value = module.paladin_network.stack_id
}

output "node_service_ids" {
  value = concat([module.paladin_admin_node.service_id], module.paladin_joiner_node[*].service_id)
}

output "node_endpoints" {
  value = concat([module.paladin_admin_node.endpoints], module.paladin_joiner_node[*].endpoints)
}

output "registry_address" {
  value = module.paladin_admin_node.registry_address
}

output "noto_factory_address" {
  value = module.noto.factory_address
}

output "pente_factory_address" {
  value = module.pente.factory_address
}
