resource "kaleido_platform_environment" "env_0" {
  name = var.environment_name
}

## KMS

resource "kaleido_platform_runtime" "keys_runtime" {
  type = "KeyManager"
  name = "keys"
  environment = kaleido_platform_environment.env_0.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "keys_service" {
  type = "KeyManager"
  name = "keys"
  environment = kaleido_platform_environment.env_0.id
  runtime = kaleido_platform_runtime.keys_runtime.id
  config_json = jsonencode({})

  database_name = var.databases != null ? var.databases.kms_db : null
}

resource "kaleido_platform_kms_wallet" "infra" {
  type = "hdwallet"
  name = "infra"
  environment = kaleido_platform_environment.env_0.id
  service = kaleido_platform_service.keys_service.id
  config_json = jsonencode({})
}

resource "kaleido_platform_kms_key" "deployer" {
  name = "deployer"
  environment = kaleido_platform_environment.env_0.id
  service = kaleido_platform_service.keys_service.id
  wallet = kaleido_platform_kms_wallet.infra.id
}


resource "kaleido_platform_kms_wallet" "users" {
  type = "hdwallet"
  name = "users"
  environment = kaleido_platform_environment.env_0.id
  service = kaleido_platform_service.keys_service.id
  config_json = jsonencode({})
}

## Contract management

resource "kaleido_platform_runtime" "contracts_runtime" {
  type = "ContractManager"
  name = "contracts"
  environment = kaleido_platform_environment.env_0.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "contracts_service" {
  type = "ContractManager"
  name = "contracts"
  environment = kaleido_platform_environment.env_0.id
  runtime = kaleido_platform_runtime.contracts_runtime.id
  config_json = jsonencode({})

  database_name = var.databases != null ? var.databases.cms_db : null
}

resource "kaleido_platform_cms_build" "erc20" {
  environment = kaleido_platform_environment.env_0.id
  service = kaleido_platform_service.contracts_service.id
  type = "precompiled"
  name = "ERC20"
  path = "Samples"
  precompiled = {
    abi = file("${path.module}/erc20.abi.json")
    bytecode = file("${path.module}/erc20.bytecode.hex")
  }
}

## FireFly v2 workflow engine

resource "kaleido_platform_runtime" "workflow_engine_runtime" {
  type = "WorkflowEngine"
  name = "flows"
  environment = kaleido_platform_environment.env_0.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "workflow_engine_service" {
  type = "WorkflowEngine"
  name = "flows"
  environment = kaleido_platform_environment.env_0.id 
  runtime = kaleido_platform_runtime.workflow_engine_runtime.id
  config_json = jsonencode({})

  database_name = var.databases != null ? var.databases.wfe_db : null
}

## Chain infrastructure: Besu testnet

## Web3 middleware: EVM connector - Ethereum Sepolia

module "evm" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/middleware-evm-connector?ref=main"
  environment_id = kaleido_platform_environment.env_0.id
  key_manager_service_id = kaleido_platform_service.keys_service.id
  jsonrpc_url            = var.evm_jsonrpc_url
  jsonrpc_auth           = var.evm_jsonrpc_auth
  ecosystem              = var.evm_ecosystem
  network                = var.evm_network
  confirmations          = var.evm_confirmations
}

## Web3 middleware: BTC connector - Bitcoin Testnet 3

module "btc" {
  source = "../../modules/middleware-btc-connector" # TODO replace with git ref once we have a release
  environment_id         = kaleido_platform_environment.env_0.id
  key_manager_service_id = kaleido_platform_service.keys_service.id
  rpc_url                = var.btc_rpc_url
  rpc_auth               = var.btc_rpc_auth
  network                = var.btc_network
  fee_rate               = var.btc_fee_rate
  monitoring             = var.btc_monitoring
}

## Digital assets: tokenization stack

resource "kaleido_platform_stack" "tokenization_stack" {
  environment = kaleido_platform_environment.env_0.id
  name = "tokenization"
  type = "digital_assets"
  sub_type = "TokenizationStack"
}

resource "kaleido_platform_runtime" "tokenization_runtime" {
  type = "AssetManager"
  name = "assets"
  environment = kaleido_platform_environment.env_0.id
  config_json = jsonencode({})
  stack_id = kaleido_platform_stack.tokenization_stack.id
}

resource "kaleido_platform_service" "tokenization_service" {
  type = "AssetManager"
  name = "assets"
  environment = kaleido_platform_environment.env_0.id
  runtime = kaleido_platform_runtime.tokenization_runtime.id
  config_json = jsonencode({
    keyManager = {
      id = kaleido_platform_service.keys_service.id
    }
  })
  stack_id = kaleido_platform_stack.tokenization_stack.id

  database_name = var.databases != null ? var.databases.ams_db : null
}

## Digital assets: custody

resource "kaleido_platform_stack" "custody_stack" {
  environment = kaleido_platform_environment.env_0.id
  name = "custody"
  type = "digital_assets"
  sub_type = "CustodyStack"
}

resource "kaleido_platform_runtime" "custody_runtime" {
  type = "WalletManager"
  name = "wallets"
  environment = kaleido_platform_environment.env_0.id
  config_json = jsonencode({})
  stack_id = kaleido_platform_stack.custody_stack.id
}

resource "kaleido_platform_service" "custody_service" {
  type        = "WalletManager"
  name        = "wallets"
  environment = kaleido_platform_environment.env_0.id
  runtime     = kaleido_platform_runtime.custody_runtime.id
  config_json = jsonencode({
    keyManager = {
      id = kaleido_platform_service.keys_service.id
    }
    assetManagerService = {
      name = kaleido_platform_service.tokenization_service.name
      service = {
        id = kaleido_platform_service.tokenization_service.id
      }
    }
  })
  stack_id   = kaleido_platform_stack.custody_stack.id
  database_name = var.databases != null ? var.databases.wms_db : null
  depends_on = [kaleido_platform_service.workflow_engine_service]
}

resource "kaleido_platform_runtime" "policy_manager_runtime" {
  type = "PolicyManager"
  name = "policies"
  environment = kaleido_platform_environment.env_0.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "policy_manager_service" {
  type        = "PolicyManager"
  name        = "policies"
  environment = kaleido_platform_environment.env_0.id
  runtime     = kaleido_platform_runtime.policy_manager_runtime.id
  config_json = jsonencode({})

  database_name = var.databases != null ? var.databases.pms_db : null
}