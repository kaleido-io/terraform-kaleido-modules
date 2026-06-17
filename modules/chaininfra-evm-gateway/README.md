# chaininfra-evm-gateway

Deploys a single EVM Gateway (`EVMGateway` runtime + service) that fronts a Besu
network with JSON-RPC, WebSocket, and GraphQL endpoints. This module is typically
composed alongside Besu nodes in the same chain-infrastructure stack:

- [`chaininfra-besu-network`](../chaininfra-besu-network) — outputs the `stack_id`
  and `network_id` this module requires
- [`chaininfra-besu-node`](../chaininfra-besu-node) — deploys validator/RPC Besu
  nodes into that stack and network (the gateway routes to the underlying chain)

Downstream modules such as [`chaininfra-block-indexer`](../chaininfra-block-indexer)
consume this module's `service_id` output as `evm_gateway_service_id`.

Service config binds the gateway to the target network via `network.id`.
`stack_id` is optional — omit it to create the gateway outside a stack. Runtime
placement defaults to `Small`. When `hostname` is set, the module binds a custom hostname to the `jsonrpc`,
`jsonrpcws`, and `graphql` endpoints.

## Usage

```hcl
module "besu_network" {
  source = "../../modules/chaininfra-besu-network"

  environment_id = kaleido_platform_environment.env.id
  network_name   = "besu"
  stack_name     = "besu"
}

module "gateway" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-evm-gateway?ref=main"

  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.besu_network.stack_id
  network_id     = module.besu_network.network_id
  gateway_name   = "besu-gateway"
  hostname       = "besu-gateway"
}
```

## Outputs

- `service_id`, `runtime_id`, `evm_gateway_name`
- `endpoints`, `hostnames`
