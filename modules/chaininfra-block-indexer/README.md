# chaininfra-block-indexer

Deploys a single Block Indexer (`BlockIndexer` runtime + service) into an existing
chain-infrastructure stack. This module can be typically composed alongside Besu nodes
and an EVM gateway in the same stack:

- [`chaininfra-besu-network`](../chaininfra-besu-network) — outputs the `stack_id`
  this module requires (and `network_id` for sibling modules such as Besu nodes and
  the EVM gateway)
- [`chaininfra-besu-node`](../chaininfra-besu-node) — deploys validator/RPC Besu
  nodes into that stack and network.
- [`chaininfra-evm-gateway`](../chaininfra-evm-gateway) — outputs the `service_id`
  passed to the optional `evm_gateway_service_id` input

Wire a ContractManager via `contract_manager_service_id` so the indexer can resolve contract metadata.

Service config connects the BlockIndexer to its upstream services; hostname defaults
to `block-indexer` and publishes `ui` and `rest` endpoints.

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

- `service_id`, `runtime_id`, `block_indexer_name`
- `endpoints`, `hostnames`
