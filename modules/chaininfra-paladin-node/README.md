# chaininfra-paladin-node

Deploys a Paladin node (`PaladinNodeRuntime` + `PaladinNodeService`) into an existing
Paladin network and stack ([chaininfra-paladin-network](../chaininfra-paladin-network)).

## Settings

| Setting | Default | Usage |
|---------|---------|-------|
| `environment_id` | required | Kaleido environment to deploy the node into |
| `network_id` / `stack_id` | required | `chaininfra-paladin-network` outputs |
| `node_name` | required | runtime/service name; the registry node's **must equal** the network's `registry_node` |
| `key_manager_service_id` | required | KeyManagerService holding the node's signing keys |
| `base_ledger` | required | `{ type = "local" }` with exactly one of `gateway_service_id` / `besu_node_service_id`, or `{ type = "endpoint" }` with `jsonrpc_url` + `ws_url` and optional basic `auth` |
| `wallets` | required | `{ kms_key_store, kms_folder_path?, zeto_wallet_prefix?, zeto_wallet_seed? }` — the `zeto_*` fields are a temporary workaround and subject to change |
| `domains` | `{}` | `baseConfig.domains` — domain plugin config keyed by domain name (merge the `domain` outputs of the noto/pente modules) |
| `base_config` | `{}` | extra Paladin config |
| `runtime_size` | `Small` | `ExtraSmall` \| `Small` \| `Medium` \| `Large` \| `ExtraLarge` |
| `runtime_zone` / `storage_size` / `storage_type` | `null` | runtime zone and storage; `null` uses platform defaults |
| `hostname` | `null` | publish the node's `jsonrpc`/`jsonrpcws` endpoints on this hostname |
| `network_registry` | `null` | the network module's `registry` output — when this node is the registry node in `deploy` mode, the module reads back the deployed registry address (`registry_address` output) |

## Usage

```hcl
# Node 1 — node_name matches the network's registry_node, so it deploys the
# registry and outputs its address.
module "paladin_node_1" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-node?ref=main"

  environment_id         = var.environment_id
  network_id             = module.paladin_network.network_id
  stack_id               = module.paladin_network.stack_id
  node_name              = "node-1" # == registry_node
  key_manager_service_id = var.kms_id
  base_ledger            = { type = "local", gateway_service_id = var.gateway_id }
  wallets                = { kms_key_store = "paladin-wallet" }
  domains                = merge(module.noto.domain, module.pente.domain)
  network_registry       = module.paladin_network.registry

  depends_on = [module.besu_node] # base ledger up before the registry deploy
}

# subsequent nodes use the registry address during creation
module "paladin_node_2" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-node?ref=main"

  # … same settings, node_name = "node-2" …
  network_registry = module.paladin_network.registry
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `PaladinNodeService` |
| `runtime_id` | ID of the `PaladinNodeRuntime` |
| `node_name` | Display name of the node runtime and service |
| `endpoints` | Map of the node's published endpoints (`jsonrpc`, `jsonrpcws`, ...) |
| `hostnames` | Map of the node's hostnames |
| `registry_address` | Deployed EVM registry address (registry node in `deploy` mode only; otherwise `null`) |
