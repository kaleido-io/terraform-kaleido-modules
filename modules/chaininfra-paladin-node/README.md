# chaininfra-paladin-node

Deploys a Paladin node — `PaladinNodeRuntime` + `PaladinNodeService` — into an existing
Paladin network and stack (see [chaininfra-paladin-network](../chaininfra-paladin-network)),
with an optional published hostname for the node's JSON-RPC endpoints.

## Prerequisites

- A Kaleido environment and a Paladin network/stack (`chaininfra-paladin-network`).
- A `KeyManagerService` with a keystore/wallet for the node's keys
  (`key_manager_service_id` + `wallets.kms_key_store`).
- A base EVM ledger the node can reach, one of:
  - an `EVMGatewayService` in the same environment (`base_ledger.gateway_service_id`, preferred),
  - a `BesuNodeService` in the same environment (`base_ledger.besu_node_service_id`),
  - an external JSON-RPC endpoint (`base_ledger.jsonrpc_url` + `ws_url`, optional basic auth).

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the node into |
| `network_id` | Paladin network to join (`chaininfra-paladin-network` `network_id` output) |
| `stack_id` | Chain-infrastructure stack (`chaininfra-paladin-network` `stack_id` output) |
| `node_name` | Runtime/service name; on the registry-admin node this **must equal** the network's `registry_admin.node_name` |
| `key_manager_service_id` | `KeyManagerService` holding the node's signing keys |
| `base_ledger` | How the node reaches the base EVM ledger (`type = "local"` with exactly one of `gateway_service_id`/`besu_node_service_id`, or `type = "endpoint"` with `jsonrpc_url` + `ws_url` and optional `auth`) |
| `registry_admin_identity` | Identity used to administer this node's registry entries; must match the network's `registry_admin.identity` in deploy mode |
| `wallets` | `{ kms_key_store, kms_folder_path?, zeto_wallet_prefix?, zeto_wallet_seed? }` — the `zeto_*` fields are a temporary workaround while zeto keys live outside KMS and are **subject to change** |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `runtime_size` | `Small` | `ExtraSmall` \| `Small` \| `Medium` \| `Large` \| `ExtraLarge` |
| `runtime_zone` | `null` | Deployment zone; `null` uses the platform default |
| `storage_size` | `null` | Runtime storage size in GB |
| `storage_type` | `null` | Runtime storage type |
| `domains` | `{}` | `baseConfig.domains` — Paladin domain plugin config keyed by domain name (noto/pente/zeto), including each factory's `registryAddress` |
| `base_config` | `{}` | Extra Paladin `baseConfig` (see boundary below) |
| `hostname` | `null` | Publish the node's `jsonrpc`/`jsonrpcws` endpoints on this hostname |
| `read_registry_address` | `false` | Set `true` on the registry-admin node to read back the deployed registry address |

`domains` and `base_config` are deliberately `any`-typed (a documented deviation from
the repo's typed-variable convention): `pldconf.PaladinConfig` is a large, open schema
owned by the Paladin project.

### baseConfig boundary

The operator seeds the node's config from `base_config`, then **overwrites** the
platform-managed sections: `db`, `log`, `blockchain`, `rpcServer`, `transports`,
`registries`, `keyManager`, `debugServer`. Only domain/sequencer/indexer-level config
(`domains`, `blockIndexer`, `sequencerManager`, `publicTxManager`, ...) is honored.

## Usage — network + N nodes

Nodes on the same network need no peering config: the operator auto-discovers and
registers every local `PaladinNodeService` on the network.

```hcl
module "paladin_network" {
  source         = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-network?ref=main"
  environment_id = var.environment_id
  network_name   = "asset-net"
  registry_mode  = "deploy"
  registry_admin = { identity = "registry.admin", node_name = "node-1" }
}

# Admin node — deploys the registry, reads back its address.
module "paladin_node_1" {
  source                  = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-node?ref=main"
  environment_id          = var.environment_id
  network_id              = module.paladin_network.network_id
  stack_id                = module.paladin_network.stack_id
  node_name               = "node-1" # == registry_admin.node_name
  registry_admin_identity = "registry.admin"
  key_manager_service_id  = var.kms_id
  base_ledger             = { type = "local", gateway_service_id = var.gateway_id }
  wallets                 = { kms_key_store = "paladin-wallet" }
  domains                 = local.domains
  read_registry_address   = true
}

# Additional nodes on the same network — auto-discovered/registered by the operator.
module "paladin_node_2" {
  source                  = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-node?ref=main"
  environment_id          = var.environment_id
  network_id              = module.paladin_network.network_id
  stack_id                = module.paladin_network.stack_id
  node_name               = "node-2"
  registry_admin_identity = "registry.admin"
  key_manager_service_id  = var.kms_id
  base_ledger             = { type = "local", gateway_service_id = var.gateway_id }
  wallets                 = { kms_key_store = "paladin-wallet" }
  domains                 = local.domains
}
```

### Bootstrap ordering (deploy mode)

The registry address is an output of the **node** module, not the network module,
because of how deploy mode bootstraps: the network is created naming the admin node;
nodes come up with no registry configured (the operator tolerates this); the operator
deploys the registry contract via the admin node; all nodes pick up the address on
reconcile and get registered; only then does the
`kaleido_platform_paladin_evm_registry` data source resolve. Set
`read_registry_address = true` on the admin node and consume its `registry_address`
output — e.g. as `existing_registry_address` for a joiner network.

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `PaladinNodeService` |
| `runtime_id` | ID of the `PaladinNodeRuntime` |
| `node_name` | Display name of the node runtime and service |
| `endpoints` | Map of the node's published endpoints (`jsonrpc`, `jsonrpcws`, ...) |
| `hostnames` | Map of the node's hostnames |
| `registry_address` | Deployed EVM registry address (admin node with `read_registry_address = true` only; otherwise `null`) |
