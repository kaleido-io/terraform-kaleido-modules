resource "kaleido_platform_environment" "env_0" {
  count = var.environment_id == "" ? 1 : 0
  name  = var.environment_name
}

locals {
  environment_id = var.environment_id != "" ? var.environment_id : kaleido_platform_environment.env_0[0].id
  node_names     = [for i in range(var.node_count) : "${var.node_name_prefix}-${i + 1}"]
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

module "block_indexer" {
  source = "../../modules/chaininfra-block-indexer"

  environment_id              = local.environment_id
  stack_id                    = module.besu_network.stack_id
  evm_gateway_service_id      = module.evm_gateway.service_id
  contract_manager_service_id = kaleido_platform_service.cms_0.id
  hostname                    = "${var.besu_network_name}-block-indexer"
}

# Key Management

resource "kaleido_platform_runtime" "kms_0" {
  type        = "KeyManager"
  name        = "kms"
  environment = local.environment_id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "kms_0" {
  type        = "KeyManager"
  name        = "kms"
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

resource "kaleido_platform_kms_key" "domain_deployer" {
  name        = "domain-deployer"
  environment = local.environment_id
  service     = kaleido_platform_service.kms_0.id
  wallet      = kaleido_platform_kms_wallet.wallet_0.name
}

# Contract Management

resource "kaleido_platform_runtime" "cms_0" {
  type        = "ContractManager"
  name        = "contracts"
  environment = local.environment_id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "cms_0" {
  type        = "ContractManager"
  name        = "contracts"
  environment = local.environment_id
  runtime     = kaleido_platform_runtime.cms_0.id
  config_json = jsonencode({})
}


resource "kaleido_platform_runtime" "wfe_0" {
  type        = "WorkflowEngine"
  name        = "flows"
  environment = local.environment_id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "wfe_0" {
  type        = "WorkflowEngine"
  name        = "flows"
  environment = local.environment_id
  runtime     = kaleido_platform_runtime.wfe_0.id
  config_json = jsonencode({})
}

# EVM Connector

data "kaleido_platform_evm_netinfo" "besu" {
  environment = local.environment_id
  service     = module.evm_gateway.service_id
  depends_on  = [module.besu_node]
}

module "evm_connector" {
  source = "../../modules/middleware-evm-connector"

  environment_id         = local.environment_id
  stack_name             = "evm"
  connector_name         = "evm-connector"
  key_manager_service_id = kaleido_platform_service.kms_0.id
  evm_gateway_service_id = module.evm_gateway.service_id

  ecosystem = { name = "besu", displayName = "Besu" }
  network = {
    name        = var.besu_network_name
    displayName = var.besu_network_name
    chainId     = tostring(data.kaleido_platform_evm_netinfo.besu.chain_id)
  }

  depends_on = [kaleido_platform_service.wfe_0]
}

# Paladin Domains

module "noto" {
  source = "../../modules/chaininfra-paladin-domain-noto"

  paladin_repo         = var.paladin_repo
  paladin_ref          = var.paladin_ref
  environment_id       = local.environment_id
  contracts_service_id = kaleido_platform_service.cms_0.id
  connector_service_id = module.evm_connector.service_id
  connector_api_name   = module.evm_connector.standard_api_name

  signing_key_address = var.signing_key_uri != null ? null : coalesce(var.signing_key_address, kaleido_platform_kms_key.domain_deployer.address)
  signing_key_uri     = var.signing_key_uri

  depends_on = [module.besu_node]
}

module "pente" {
  source = "../../modules/chaininfra-paladin-domain-pente"

  paladin_repo         = var.paladin_repo
  paladin_ref          = var.paladin_ref
  environment_id       = local.environment_id
  contracts_service_id = kaleido_platform_service.cms_0.id
  connector_service_id = module.evm_connector.service_id
  connector_api_name   = module.evm_connector.standard_api_name

  signing_key_address = var.signing_key_uri != null ? null : coalesce(var.signing_key_address, kaleido_platform_kms_key.domain_deployer.address)
  signing_key_uri     = var.signing_key_uri

  # Deploy one domain at a time — both use the same signing key and EVM connector.
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
  registry_node = local.node_names[0]
}

module "paladin_node" {
  source = "../../modules/chaininfra-paladin-node"
  count  = var.node_count

  environment_id         = local.environment_id
  network_id             = module.paladin_network.network_id
  stack_id               = module.paladin_network.stack_id
  node_name              = local.node_names[count.index]
  key_manager_service_id = kaleido_platform_service.kms_0.id

  base_ledger = {
    type               = "local"
    gateway_service_id = module.evm_gateway.service_id
  }

  wallets = {
    kms_key_store   = kaleido_platform_kms_wallet.wallet_0.name
    kms_folder_path = local.node_names[count.index]
  }

  domains = local.domains

  hostname         = var.publish_hostnames ? local.node_names[count.index] : null
  network_registry = module.paladin_network.registry

  depends_on = [module.besu_network, module.besu_node, module.evm_gateway]
}

# Outputs

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

output "noto_factory_address" {
  value = module.noto.factory_address
}

output "pente_factory_address" {
  value = module.pente.factory_address
}
