# middleware-evm-connector

Deploys an EVM connector service (`EVMConnectorStack` + runtime + service) with
config types, config profiles, connector flows, stream factories, and the standard
API it ships with. Per-ecosystem behaviour is controlled by the typed config-profile
variables.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the connector into |
| `key_manager_service_id` | ID of the `KeyManager` service used to sign EVM transactions |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `stack_name` | `evm` | Name of the `EVMConnectorStack` |
| `connector_name` | `evm-connector` | Display name of the runtime and service |
| `runtime_size` | `Small` | `EVMConnector` runtime size |
| `runtime_zone` | `null` | Deployment zone; `null` uses the platform default |
| `database_name` | `null` | External database name; required only on instances with externally-provisioned databases |
| `evm_gateway_service_id` | `null` | [`service_id`](../chaininfra-evm-gateway#outputs) from [`chaininfra-evm-gateway`](../chaininfra-evm-gateway) for Kaleido-managed Besu networks |
| `jsonrpc_url` | `null` | External JSON-RPC URL for public networks |
| `jsonrpc_auth` | `null` | Basic-auth credentials for the JSON-RPC endpoint (sensitive) |
| `ecosystem` | `null` | Ecosystem metadata (e.g. `{ name = "ethereum", displayName = "Ethereum" }`) |
| `network` | `null` | Network metadata (e.g. `{ name = "ethereum-mainnet", chainId = "1" }`) |
| `confirmations` | `{}` | `evm.confirmations` — confirmation count and resubmission policy |
| `gas_estimation` | `{}` | `evm.gasEstimation` — gas estimate scale factor |
| `gas_pricing` | `{}` | `evm.gasPricing` — fee format, source, auto-increment, and caps |
| `nonce_assignment` | `{}` | `evm.nonceAssignment` |
| `submission` | `{}` | `evm.submission` — error-type matchers for submission retries |
| `transaction_serialization` | `{}` | `evm.transactionSerialization` |
| `block_events` | `{}` | `evm.blockEventsConfig` — latest-block poller debounce timings |
| `transaction_events` | `{}` | `evm.transactionEventsConfig` — block-walking event stream tuning |
| `contract_event_listener` | `{}` | `evm.contractEventListener` — contract address + event ABI listener |

## Usage

```hcl
module "evm" {
  source = "https://github.com/kaleido-io/terraform-kaleido-modules/modules/middleware-evm-connector?ref=main"

  environment_id         = kaleido_platform_environment.env.id
  key_manager_service_id = kaleido_platform_service.keymanager.id

  ecosystem = { name = "besu", displayName = "Besu" }
  network   = { name = "besu-private", chainId = "3333" }

  confirmations = { count = 0 }
}
```

## Ecosystem presets

Drop-in `*.tfvars` files under `examples/`:

| File | Notes |
|------|-------|
| `besu.tfvars` | Private Besu, count=0, fixed zero-fee gas |
| `ethereum-mainnet.tfvars` | 12 confirmations, resubmission on |
| `ethereum-sepolia.tfvars` | 6 confirmations, resubmission on |
| `base-mainnet.tfvars` | 20 confirmations |
| `base-sepolia.tfvars` | 6 confirmations |
| `polygon-mainnet.tfvars` | 50 confirmations (reorg risk) |
| `polygon-amoy.tfvars` | 50 confirmations (reorg risk) |
| `arbitrum-sepolia.tfvars` | 6 confirmations |

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `EVMConnector` service |
| `stack_id` | ID of the `EVMConnectorStack` |
| `runtime_id` | ID of the `EVMConnector` runtime |
| `submission_flow_name` | Name of the deployed submission connector flow |
| `submission_flow_id` | ID of the deployed submission connector flow |
| `query_flow_name` | Name of the deployed query connector flow |
| `query_flow_id` | ID of the deployed query connector flow |
| `flow_ids` | Map of connector flow name to deployed flow ID (`submission`, `query`) |
| `standard_api_name` | Name of the deployed EVM standard API |
| `standard_api_id` | ID of the deployed EVM standard API |
| `stream_factories` | Map of deployed stream factory IDs (`block_events`, `transaction_events`) |
| `config_profiles` | Map of config-type name to deployed config profile ID |

The flow IDs exist because workflow **subflow bindings take an ID, not a name**
(`subflowBindings: { <subflow>: { subflowId: "flw:..." } }`). Without them a
caller cannot bind its own `kaleido_platform_wfe_workflow` to the connector's
flows, since Terraform forbids referencing a module's internal resources.
