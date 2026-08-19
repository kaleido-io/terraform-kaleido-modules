resource "kaleido_platform_environment" "env" {
  name = var.environment_name
}

# ─── Key Manager ──────────────────────────────────────────────────────────────

resource "kaleido_platform_runtime" "keys" {
  type        = "KeyManager"
  name        = var.key_manager_name
  environment = kaleido_platform_environment.env.id
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "keys" {
  type        = "KeyManager"
  name        = var.key_manager_name
  environment = kaleido_platform_environment.env.id
  runtime     = kaleido_platform_runtime.keys.id
  config_json = jsonencode({})
}

# ─── EVM Connector with dynamic gas pricing ───────────────────────────────────

module "evm_connector" {
  source = "../../modules/middleware-evm-connector"

  environment_id         = kaleido_platform_environment.env.id
  key_manager_service_id = kaleido_platform_service.keys.id

  ecosystem = {
    name        = "ethereum"
    displayName = "Ethereum"
  }

  network = {
    name        = "ethereum-sepolia-testnet"
    displayName = "Ethereum Sepolia Testnet"
    chainId     = "11155111"
  }

  jsonrpc_url            = var.jsonrpc_url
  jsonrpc_auth           = var.jsonrpc_auth
  evm_gateway_service_id = var.evm_gateway_service_id

  # Nonce assignment — static binding by config profile ID.
  # The optional `name` field gives the profile a custom name; omitting it
  # defaults to the config type name ("evm.nonceAssignment"). Either way the
  # module creates a kaleido_platform_connector_config_profile resource and
  # binds it to the submission flow via kaleido_platform_connector_flow_config_binding
  # using the profile's ID.
  # requireSubmitted ensures a transaction reaches the mempool before the next
  # nonce is assigned, preventing gaps from stale in-flight transactions.
  nonce_assignment = {
    name                  = "my_nonce_assignment"
    previousTxnsCondition = "requireSubmitted"
  }

  # Dynamic gas pricing — set gas_pricing = null so the module uses dynamic_mapping
  # instead of a static binding. All named profiles (including the fallback) are
  # supplied via gas_pricing_profiles with their full profile names as keys.
  gas_pricing = null

  # Named profiles for dynamic selection. Keys are full profile names.
  # Callers select a profile by passing options.gasPricing.configProfileName in
  # the transaction request (e.g. "evm.gasPricing_high").
  gas_pricing_profiles = {
    # Fallback — used when no configProfileName is supplied in the transaction.
    "evm.gasPricing" = {
      format = { name = "eip1559", enableLegacyFallback = true }
      source = {
        RPCEndpoint = {
          ethFeeHistory = {
            priorityFeePercentile = 60
            historyBlockCount     = 10
            baseFeeBufferFactor   = 1.15
          }
        }
      }
    }
    "evm.gasPricing_low" = {
      format = { name = "eip1559", enableLegacyFallback = true }
      source = {
        RPCEndpoint = {
          ethFeeHistory = {
            priorityFeePercentile = 50
            historyBlockCount     = 15
            baseFeeBufferFactor   = 1.05
          }
        }
      }
    }
    "evm.gasPricing_high" = {
      format = { name = "eip1559", enableLegacyFallback = true }
      source = {
        RPCEndpoint = {
          ethFeeHistory = {
            priorityFeePercentile = 80
            historyBlockCount     = 7
            baseFeeBufferFactor   = 1.25
          }
        }
      }
    }
  }

  # Dynamic mapping — sets a JSONata expression on the submission flow's gasPricing
  # config-profile binding. At submission time the connector evaluates the expression
  # against the transaction state to pick the profile name, then prepends the
  # connector service ID as a namespace prefix before resolving the profile.
  # Falls back to the default "evm.gasPricing" profile when no configProfileName
  # is present in the transaction options.
  gas_pricing_dynamic_mapping = {
    jsonata = "$exists(state.input.options.gasPricing.configProfileName) ? state.input.options.gasPricing.configProfileName : \"evm.gasPricing\""
  }
}

# ─── Outputs ──────────────────────────────────────────────────────────────────

output "named_profile_names" {
  value       = module.evm_connector.named_profile_names
  description = "Named profiles available for dynamic selection."
}
