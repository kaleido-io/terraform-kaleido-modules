# chaininfra-block-indexer

Deploys a single Block Indexer (`BlockIndexer` runtime + service) into an existing
chain-infrastructure stack. The indexer connects to an EVM gateway and optionally a
ContractManager for contract metadata.

## Required Settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the indexer into |
| `stack_id` | [`stack_id`](../chaininfra-besu-network#outputs) from [`chaininfra-besu-network`](../chaininfra-besu-network) — chain-infrastructure stack the indexer belongs to |
| `evm_gateway_service_id` | [`service_id`](../chaininfra-evm-gateway#outputs) from [`chaininfra-evm-gateway`](../chaininfra-evm-gateway) — `EVMGateway` service the indexer reads from |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `block_indexer_name` | `block-indexer` | Display name of the runtime and service |
| `contract_manager_service_id` | `""` | ID of the `ContractManager` service for contract metadata resolution |
| `hostname` | `block-indexer` | Custom hostname; publishes `ui` and `rest` endpoints |
| `blockindexer_size` | `null` | Runtime size (`ExtraSmall`–`ExtraLarge`); `null` uses the platform default |

## Usage

```hcl
module "block_indexer" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-block-indexer?ref=main"

  environment_id              = kaleido_platform_environment.env.id
  stack_id                    = module.besu_network.stack_id
  evm_gateway_service_id      = module.gateway.service_id
  contract_manager_service_id = kaleido_platform_service.contract_manager.id
  hostname                    = "besu-block-indexer"
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `BlockIndexer` service |
| `runtime_id` | ID of the `BlockIndexer` runtime |
| `block_indexer_name` | Display name of the runtime and service |
| `endpoints` | Map of published service endpoints |
| `hostnames` | Map of custom hostnames bound to the service |
