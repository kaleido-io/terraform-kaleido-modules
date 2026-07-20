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

  jsonrpc_url  = var.jsonrpc_url
  jsonrpc_auth = var.jsonrpc_auth

  # Default profile — used when no configProfileName is supplied in the transaction.
  gas_pricing = {
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

  # Named profiles — each becomes a config profile named "evm.gasPricing_<key>".
  # Callers select a profile by passing options.gasPricing.configProfileName in
  # the transaction request (e.g. "evm.gasPricing_high").
  gas_pricing_profiles = {
    low = {
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
    high = {
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

output "gas_pricing_profile_names" {
  value       = module.evm_connector.gas_pricing_profile_names
  description = "Named gas pricing profiles available for dynamic selection."
}
