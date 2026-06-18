resource "kaleido_platform_environment" "env" {
  name = var.environment_name
}

# Contract Management

resource "kaleido_platform_runtime" "contract_manager_runtime"{
  type = "ContractManager"
  name = "contract-manager"
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "contract_manager_service"{
  type = "ContractManager"
  name = "contract-manager"
  environment = kaleido_platform_environment.env.id
  runtime = kaleido_platform_runtime.contract_manager_runtime.id
  config_json=jsonencode({})
}

# Besu Network

module "besu_network" {
  source = "../../modules/chaininfra-besu-network"

  environment_id = kaleido_platform_environment.env.id
  network_name   = var.network_name
  stack_name     = var.stack_name
  chain_id = var.chain_id

  initial_balances = {
    "0x12F62772C4652280d06E64CfBC9033d409559aD4" = "0x111111111111"
  }

  genesis_json = var.genesis_json != null ? file(var.genesis_json) : null

  qbft = {
    blockperiodseconds = 10
    epochlength = 1000
  }
}

# Besu Nodes

module "besu_validator_nodes" {
  source = "../../modules/chaininfra-besu-node"

  environment_id = kaleido_platform_environment.env.id
  network_id     = module.besu_network.network_id
  node_name      = "besu-validator-${count.index}"
  signer         = true
  stack_id       = module.besu_network.stack_id
  count = var.validator_count
  node_key = length(var.validator_node_keys) > 0 && count.index < length(var.validator_node_keys) ? var.validator_node_keys[count.index] : null
}

module "besu_rpc_nodes" {
  source = "../../modules/chaininfra-besu-node"

  environment_id = kaleido_platform_environment.env.id
  network_id     = module.besu_network.network_id
  node_name      = "besu-rpc-${count.index}"
  signer         = false
  stack_id       = module.besu_network.stack_id
  apis_enabled   = ["TRACE"]
  count = var.rpc_node_count
}

# EVM Gateway

module "gateway" {
  source = "../../modules/chaininfra-evm-gateway"

  environment_id = kaleido_platform_environment.env.id
  network_id     = module.besu_network.network_id
  gateway_name   = "besu-gateway"
  stack_id       = module.besu_network.stack_id
  hostname = "besu-gateway"
}

# Block Indexer

module "block_indexer" {
  source = "../../modules/chaininfra-block-indexer"

  environment_id = kaleido_platform_environment.env.id
  network_id     = module.besu_network.network_id
  stack_id       = module.besu_network.stack_id
  evm_gateway_service_id = module.gateway.service_id
  contract_manager_service_id = kaleido_platform_service.contract_manager_service.id
  hostname = "besu-block-indexer"
}

# Blockchain Application Firewall

module "baf" {
  source = "../../modules/chaininfra-baf"

  environment_id = kaleido_platform_environment.env.id
  network_id     = module.besu_network.network_id
  stack_name     = "${var.stack_name}-baf"
  policies       = var.baf_policies
  count = var.baf_enabled ? 1 : 0
}
