# chaininfra-evm-gateway

Deploys a single EVM Gateway (`EVMGateway` runtime + service) that fronts a Besu
network with JSON-RPC, WebSocket, and GraphQL endpoints.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the gateway into |
| `gateway_name` | Display name of the runtime and service |
| `network_id` | [`network_id`](../chaininfra-besu-network#outputs) from [`chaininfra-besu-network`](../chaininfra-besu-network) — `BesuNetwork` the gateway fronts |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `stack_id` | `null` | [`stack_id`](../chaininfra-besu-network#outputs) from [`chaininfra-besu-network`](../chaininfra-besu-network) — chain-infrastructure stack; `null` creates the gateway outside a stack |
| `runtime_size` | `Small` | EVM Gateway runtime size |
| `hostname` | `null` | Custom hostname; when set, binds `jsonrpc`, `jsonrpcws`, and `graphql` endpoints |

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

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `EVMGateway` service |
| `runtime_id` | ID of the `EVMGateway` runtime |
| `evm_gateway_name` | Display name of the runtime and service |
| `endpoints` | Map of published service endpoints |
| `hostnames` | Map of custom hostnames bound to the service |
