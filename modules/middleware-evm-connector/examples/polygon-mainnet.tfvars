# Polygon mainnet — 50 confirmations to handle reorg risk, per
# <upstream>/evm/ecosystems/polygon.yaml.

ecosystem   = { name = "polygon", displayName = "Polygon" }
network     = { name = "polygon-mainnet", displayName = "Polygon Mainnet", chainId = "137" }
# Contact Kaleido support to get a JSONRPC URL for Arbitrum Sepolia testnet
jsonrpc_url = "https://polygon-mainnet.rpc.example.com"
jsonrpc_auth = { username = "REPLACE_ME", password = "REPLACE_ME" }

confirmations = {
  count = 50
  resubmission = {
    enabled = true
  }
}
