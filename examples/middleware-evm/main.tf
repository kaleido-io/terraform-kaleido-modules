# Pre-London Besu chain + EVM connector, exercising legacy (EIP-155) transactions.
#
# Test plan: kaleido-io/kaleido-planning#7288 ("Multiple profiles").
# Reproduces the shape of support ticket #1753: a customer Besu chain that only
# accepts legacy (type-0) transactions because London never activates. With the
# firefly-signer EIP-155 fix in place, a `format: "legacy"` gasPricing profile lets
# the connector sign and submit a legacy transaction with the correct chain ID
# (no "wrong chain ID" rejection).
#
# NOTE on faithfulness to the customer's chain: the platform Besu plugin always
# forces `berlinBlock: 0` ("all chains are berlin minimum" — service-manager
# /plugins/besu/besu.go), so we cannot reproduce a literally pre-Berlin chain.
# Omitting londonBlock is sufficient: London never activates, so the node accepts
# legacy transactions only — which is the condition that triggered #1753.

resource "kaleido_platform_environment" "env" {
  name = var.environment_name
}

## Key Manager — HD wallet + the key we pre-fund in genesis ─────────────────────

resource "kaleido_platform_runtime" "keys_runtime" {
  type        = "KeyManager"
  name        = "keys"
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "keys_service" {
  type        = "KeyManager"
  name        = "keys"
  environment = kaleido_platform_environment.env.id
  runtime     = kaleido_platform_runtime.keys_runtime.id
  config_json = jsonencode({})
}

resource "kaleido_platform_kms_wallet" "hd" {
  type        = "hdwallet"
  name        = "hd"
  environment = kaleido_platform_environment.env.id
  service     = kaleido_platform_service.keys_service.id
  config_json = jsonencode({})
}

resource "kaleido_platform_kms_key" "deployer" {
  name        = "deployer"
  environment = kaleido_platform_environment.env.id
  service     = kaleido_platform_service.keys_service.id
  wallet      = kaleido_platform_kms_wallet.hd.id
}

## Chain infrastructure — single-node, pre-London Besu network ───────────────────

resource "kaleido_platform_stack" "besu_stack" {
  environment = kaleido_platform_environment.env.id
  name        = "besu"
  type        = "chain_infrastructure"
  network_id  = kaleido_platform_network.besu_network.id
}

resource "kaleido_platform_network" "besu_network" {
  type        = "Besu"
  name        = "besu"
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({
    chainID = var.chain_id
    bootstrapOptions = {
      # Pre-London: declare an explicit eipBlockConfig with NO londonBlock. This is
      # deliberate — if eipBlockConfig is omitted entirely the plugin applies its
      # default `shanghaiTime: 0` / `osakaTime: 0`, which would implicitly activate
      # London (and later) at genesis and defeat the test. berlinBlock is forced to
      # 0 by the plugin regardless; we restate it to document intent.
      eipBlockConfig = {
        berlinBlock = 0
      }
      qbft = {
        blockperiodseconds = 2
      }
      # Pre-fund the connector's deployer key directly in genesis.
      initialBalances = {
        (kaleido_platform_kms_key.deployer.address) = var.initial_balance
      }
    }
  })
}

resource "kaleido_platform_runtime" "besu_node_runtime" {
  type        = "BesuNode"
  name        = "besu-node-1"
  environment = kaleido_platform_environment.env.id
  stack_id    = kaleido_platform_stack.besu_stack.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "besu_node_service" {
  type        = "BesuNode"
  name        = "besu-node-1"
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
  name        = "besu-gateway"
  environment = kaleido_platform_environment.env.id
  stack_id    = kaleido_platform_stack.besu_stack.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "evm_gateway_service" {
  type        = "EVMGateway"
  name        = "besu-gateway"
  environment = kaleido_platform_environment.env.id
  runtime     = kaleido_platform_runtime.evm_gateway_runtime.id
  stack_id    = kaleido_platform_stack.besu_stack.id
  config_json = jsonencode({
    network = {
      id = kaleido_platform_network.besu_network.id
    }
  })
}

## Web3 middleware — EVM connector via the shared module ─────────────────────────
#
# The module's bound gasPricing profile is the one the submission flow uses. We set
# it to the *recommended* legacy profile so a legacy (EIP-155) transaction is what
# actually gets signed and submitted — this is what validates the firefly-signer
# fix. `format.name = "legacy"` makes the connector price via `eth_gasPrice` rather
# than `eth_feeHistory`.

resource "kaleido_platform_runtime" "contracts_runtime" {
  type = "ContractManager"
  name = "contracts"
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "contracts_service" {
  type = "ContractManager"
  name = "contracts"
  environment = kaleido_platform_environment.env.id
  runtime = kaleido_platform_runtime.contracts_runtime.id
  config_json = jsonencode({})
}

## FireFly v2 workflow engine

resource "kaleido_platform_runtime" "workflow_engine_runtime" {
  type = "WorkflowEngine"
  name = "flows"
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "workflow_engine_service" {
  type = "WorkflowEngine"
  name = "flows"
  environment = kaleido_platform_environment.env.id
  runtime = kaleido_platform_runtime.workflow_engine_runtime.id
  config_json = jsonencode({})
}

module "evm" {
  source = "../../modules/middleware-evm-connector"

  environment_id         = kaleido_platform_environment.env.id
  key_manager_service_id = kaleido_platform_service.keys_service.id
  evm_gateway_service_id = kaleido_platform_service.evm_gateway_service.id
  stack_name             = "evm"
  connector_name         = "evm-connector"

  ecosystem = {
    name        = "besu"
    displayName = "Besu"
  }
  network = {
    name        = "besu-prelondon"
    displayName = "Besu (pre-London)"
    chainId     = tostring(var.chain_id)
  }

  # Single signer → immediate finality.
  confirmations = { count = 0 }

  depends_on = [kaleido_platform_service.workflow_engine_service]
}

## Secondary gasPricing profile — customer-style legacy ──────────────────────────
#
# Manually create a *second* evm.gasPricing profile on the connector service AFTER
# the module has run, mirroring the customer's own profile (cache TTL/size,
# auto-increment multiplier, live non-fixed price) but with `format: "legacy"`
# pinned. This is "our recommended profile paired with the fix" expressed as the
# customer would have configured it. Swap the submission flow's evm.gasPricing
# binding to this profile to test their exact configuration.
#
# The config TYPE `evm.gasPricing` is registered by the module; this is an
# additional named PROFILE of that same type, so it must use a distinct `name`.

resource "kaleido_platform_connector_config_profile" "legacy_customer" {
  environment = kaleido_platform_environment.env.id
  service     = module.evm.service_id
  name        = "legacyHighGasPrice"
  config_type = "evm.gasPricing"
  value_json = jsonencode({
    format = { name = "legacy" }
    source = {
      RPCEndpoint = {
        cache = {
          enabled = true
          size    = "80"
          ttl     = "30s"
        }
      }
    }
    autoIncrement = {
      enabled  = true
      gasPrice = { multiplier = 1.125 }
    }
    caps = {
      enabled  = true
      gasPrice = 100000000000 // 100 gwei
    }
  })

  depends_on = [module.evm]
}

## Outputs ───────────────────────────────────────────────────────────────────────

output "environment_id" {
  value = kaleido_platform_environment.env.id
}

output "deployer_address" {
  value = kaleido_platform_kms_key.deployer.address
}

output "evm_connector_service_id" {
  value = module.evm.service_id
}

output "gas_pricing_profiles" {
  description = "Bound (module) legacy profile + the secondary customer-style legacy profile."
  value = {
    bound           = module.evm.config_profiles["evm.gasPricing"]
    legacy_customer = kaleido_platform_connector_config_profile.legacy_customer.id
  }
}
