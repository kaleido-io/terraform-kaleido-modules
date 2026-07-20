# Example: category-based gas pricing tiers with dynamic profile selection.
# Transactions pass `input.options.gasPricing.configProfileName` (e.g. "evm.gasPricing_high")
# and the connector selects the matching profile automatically.

ecosystem   = { name = "ethereum", displayName = "Ethereum" }
network     = { name = "ethereum-sepolia-testnet", displayName = "Ethereum Sepolia Testnet", chainId = "11155111" }
jsonrpc_url = "https://ethereum-sepolia-testnet.rpc.example.com"
jsonrpc_auth = { username = "REPLACE_ME", password = "REPLACE_ME" }

# Default profile used when no configProfileName is supplied in the transaction.
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

# Named profiles for dynamic tier selection.
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

# Route transactions to named profiles based on the submission payload.
# Falls back to the default "evm.gasPricing" profile when no configProfileName is provided.
gas_pricing_dynamic_mapping = {
  jsonata = "$exists(state.input.options.gasPricing.configProfileName) ? state.input.options.gasPricing.configProfileName : \"evm.gasPricing\""
}
