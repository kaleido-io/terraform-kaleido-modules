resource "kaleido_platform_environment" "env" {
  name = var.environment_name
}

## Key Manager

resource "kaleido_platform_runtime" "keys_runtime" {
  type = "KeyManager"
  name = var.key_manager_name
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "keys_service" {
  type = "KeyManager"
  name = var.key_manager_name
  environment = kaleido_platform_environment.env.id
  runtime = kaleido_platform_runtime.keys_runtime.id
  config_json = jsonencode({})

  database_name = var.databases != null ? var.databases.kms_db : null
}

resource "kaleido_platform_kms_wallet" "infra" {
  type = "hdwallet"
  name = "infra"
  environment = kaleido_platform_environment.env.id
  service = kaleido_platform_service.keys_service.id
  config_json = jsonencode({})
}

resource "kaleido_platform_kms_key" "deployer" {
  name = "deployer"
  environment = kaleido_platform_environment.env.id
  service = kaleido_platform_service.keys_service.id
  wallet = kaleido_platform_kms_wallet.infra.id
}


resource "kaleido_platform_kms_wallet" "users" {
  type = "hdwallet"
  name = "users"
  environment = kaleido_platform_environment.env.id
  service = kaleido_platform_service.keys_service.id
  config_json = jsonencode({})
}

## Contract Manager

resource "kaleido_platform_runtime" "contracts_runtime" {
  type = "ContractManager"
  name = var.contract_manager_name
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "contracts_service" {
  type = "ContractManager"
  name = var.contract_manager_name
  environment = kaleido_platform_environment.env.id
  runtime = kaleido_platform_runtime.contracts_runtime.id
  config_json = jsonencode({})

  database_name = var.databases != null ? var.databases.cms_db : null
}

## Web3 Middleware

resource "kaleido_platform_stack" "web3_middleware_stack" {
  environment = kaleido_platform_environment.env.id
  name = var.web3_middleware_stack_name
  type = "web3_middleware"
}

## Transaction Manager 

resource "kaleido_platform_runtime" "transaction_manager_runtime" {
  type = "TransactionManager"
  name = var.transaction_manager_name
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
  stack_id = kaleido_platform_stack.web3_middleware_stack.id
}

resource "kaleido_platform_service" "transaction_manager_service" {
  type = "TransactionManager"
  name = var.transaction_manager_name
  environment = kaleido_platform_environment.env.id
  runtime = kaleido_platform_runtime.transaction_manager_runtime.id
  stack_id = kaleido_platform_stack.web3_middleware_stack.id
  config_json = jsonencode({
    keyManager = {
      id: kaleido_platform_service.keys_service.id
    }
    type = "evm"
    evm = {
      confirmations = {
        required = 0
      }
      connector = {
        evmGateway = {
          id =  kaleido_platform_service.evm_gateway_service.id
        }
      }
    }
  })
}

## Firefly V1.x - Gateway Mode 

resource "kaleido_platform_runtime" "firefly_runtime" {
  type = "FireFly"
  name = var.firefly_name
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
  stack_id = kaleido_platform_stack.web3_middleware_stack.id
}

resource "kaleido_platform_service" "firefly_service" {
  type = "FireFly"
  name = var.firefly_name
  environment = kaleido_platform_environment.env.id
  runtime = kaleido_platform_runtime.firefly_runtime.id
  stack_id = kaleido_platform_stack.web3_middleware_stack.id
  config_json = jsonencode({
    transactionManager = {
      id = kaleido_platform_service.transaction_manager_service.id
    }
  })
}

## Chain infrastructure: single-node Besu network

resource "kaleido_platform_stack" "besu_stack" {
  environment = kaleido_platform_environment.env.id
  name        = var.besu_stack_name
  type        = "chain_infrastructure"
  network_id  = kaleido_platform_network.besu_network.id
}

resource "kaleido_platform_network" "besu_network" {
  type        = "Besu"
  name        = var.besu_network_name
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({
    bootstrapOptions = {
      blockConfigFlags = {
        zeroBaseFee = true
      }
      eipBlockConfig = {
        shanghaiTime = 0
      }
      qbft = {
        blockperiodseconds = 2
      }
    }
  })
}

resource "kaleido_platform_runtime" "besu_node_runtime" {
  type        = "BesuNode"
  name        = var.besu_node_name
  environment = kaleido_platform_environment.env.id
  stack_id    = kaleido_platform_stack.besu_stack.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "besu_node_service" {
  type        = "BesuNode"
  name        = var.besu_node_name
  environment = kaleido_platform_environment.env.id
  runtime     = kaleido_platform_runtime.besu_node_runtime.id
  stack_id    = kaleido_platform_stack.besu_stack.id
  config_json = jsonencode({
    network = {
      id = kaleido_platform_network.besu_network.id
    }
  })
}

resource "kaleido_platform_runtime" "evm_gateway_runtime" {
  type        = "EVMGateway"
  name        = var.evm_gateway_name
  environment = kaleido_platform_environment.env.id
  stack_id    = kaleido_platform_stack.besu_stack.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "evm_gateway_service" {
  type        = "EVMGateway"
  name        = var.evm_gateway_name
  environment = kaleido_platform_environment.env.id
  runtime     = kaleido_platform_runtime.evm_gateway_runtime.id
  stack_id    = kaleido_platform_stack.besu_stack.id
  config_json = jsonencode({
    network = {
      id = kaleido_platform_network.besu_network.id
    }
  })
}

data "kaleido_platform_evm_netinfo" "besu" {
  environment = kaleido_platform_environment.env.id
  service     = kaleido_platform_service.evm_gateway_service.id
  depends_on = [
    kaleido_platform_service.besu_node_service,
    kaleido_platform_service.evm_gateway_service,
  ]
}

## Digital assets: tokenization stack

resource "kaleido_platform_stack" "tokenization_stack" {
  environment = kaleido_platform_environment.env.id
  name = var.tokenization_stack_name
  type = "digital_assets"
  sub_type = "TokenizationStack"
}

resource "kaleido_platform_runtime" "tokenization_runtime" {
  type = "AssetManager"
  name = var.asset_manager_name
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
  stack_id = kaleido_platform_stack.tokenization_stack.id
}

resource "kaleido_platform_service" "tokenization_service" {
  type = "AssetManager"
  name = var.asset_manager_name
  environment = kaleido_platform_environment.env.id
  runtime = kaleido_platform_runtime.tokenization_runtime.id
  config_json = jsonencode({
    keyManager = {
      id = kaleido_platform_service.keys_service.id
    }
  })
  stack_id = kaleido_platform_stack.tokenization_stack.id

  database_name = var.databases != null ? var.databases.ams_db : null
}


## Block Indexer 

resource "kaleido_platform_runtime" "block_indexer_runtime" {
  type = "BlockIndexer"
  name = var.block_indexer_name
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
}   

resource "kaleido_platform_service" "block_indexer_service" {
  type = "BlockIndexer"
  name = var.block_indexer_name
  environment = kaleido_platform_environment.env.id
  runtime = kaleido_platform_runtime.block_indexer_runtime.id
  database_name = var.databases != null ? var.databases.bis_db : null
  config_json = jsonencode({
    contractManager = {
      id = kaleido_platform_service.contracts_service.id
    }
    evmGateway = {
      id = kaleido_platform_service.evm_gateway_service.id
    }
  })
  hostnames = { (var.block_indexer_hostname) = ["ui", "rest"] }

  depends_on = [data.kaleido_platform_evm_netinfo.besu]
}