# middleware-btc-connector

Deploys a Bitcoin connector service (`BTCConnectorStack` + runtime + service) with
config types, config profiles, a submission flow, transaction-events stream factory,
and the Bitcoin standard API it ships with.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the connector into |
| `key_manager_service_id` | ID of the `KeyManager` service used to sign Bitcoin transactions |
| `network` | Network metadata (`mainnet`, `testnet4`, `testnet`, or `signet`) |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `stack_name` | `btc` | Name of the `BTCConnectorStack` |
| `connector_name` | `btc-connector` | Display name of the runtime and service |
| `rpc_url` | `null` | Bitcoin Core RPC URL |
| `rpc_auth` | `null` | Basic-auth credentials for the Bitcoin Core RPC endpoint (sensitive) |
| `ecosystem` | `{ name = "bitcoin", displayName = "Bitcoin" }` | Ecosystem metadata |
| `fee_rate` | `{}` | `btc.feeRate` — auto-increment, max fee cap, and fee source |
| `assembly` | `{ changeOutputPosition = "last" }` | `btc.assembly` — change output position (`last` or `random`) |
| `monitoring` | `{}` | `btc.monitoring` — confirmation count, polling interval, stale timeout |
| `transaction_events` | `{}` | `btc.transactionEventsConfig` — event stream tuning |

## Usage

```hcl
module "btc" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/middleware-btc-connector?ref=main"

  environment_id         = kaleido_platform_environment.env.id
  key_manager_service_id = kaleido_platform_service.keymanager.id

  network = { name = "testnet4", displayName = "Bitcoin Testnet 4" }
}
```

## Ecosystem presets

| File | Notes |
|------|-------|
| `bitcoin-mainnet.tfvars` | 6 confirmations, RPC-based fee estimation, 100 sat/vB cap |
| `bitcoin-testnet3.tfvars` | 2 confirmations, RPC fee estimation |
| `bitcoin-testnet4.tfvars` | 2 confirmations, RPC fee estimation |
| `bitcoin-signet.tfvars` | 1 confirmation, fixed 1 sat/vB fee |

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `BTCConnector` service |
| `stack_id` | ID of the `BTCConnectorStack` |
| `runtime_id` | ID of the `BTCConnector` runtime |
| `submission_flow_name` | Name of the deployed submission connector flow |
| `standard_api_name` | Name of the deployed Bitcoin standard API |
| `stream_factories` | Map of deployed stream factory IDs (`transaction_events`) |
| `config_profiles` | Map of config-type name to deployed config profile ID |
