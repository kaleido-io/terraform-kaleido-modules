# chaininfra-paladin-node

Deploys a Paladin node (`PaladinNodeRuntime` + `PaladinNodeService`) into an existing
Paladin network and stack ([chaininfra-paladin-network](../chaininfra-paladin-network)),
with an optional published hostname for the node's JSON-RPC endpoints. Nodes on the
same network need no peering config — the operator auto-discovers and registers every
local node.

## Settings

| Setting | Default | Usage |
|---------|---------|-------|
| `environment_id` | required | Kaleido environment to deploy the node into |
| `network_id` / `stack_id` | required | `chaininfra-paladin-network` outputs |
| `node_name` | required | runtime/service name; the registry-admin node's **must equal** the network's `registry_admin.node_name` |
| `key_manager_service_id` | required | KeyManagerService holding the node's signing keys |
| `base_ledger` | required | `{ type = "local" }` with exactly one of `gateway_service_id` / `besu_node_service_id`, or `{ type = "endpoint" }` with `jsonrpc_url` + `ws_url` and optional basic `auth` |
| `registry_admin_identity` | required | identity administering this node's registry entries; must match the network's `registry_admin.identity` in deploy mode |
| `wallets` | required | `{ kms_key_store, kms_folder_path?, zeto_wallet_prefix?, zeto_wallet_seed? }` — the `zeto_*` fields are a temporary workaround and subject to change |
| `domains` | `{}` | `baseConfig.domains` — domain plugin config keyed by domain name (merge the `domain` outputs of the noto/pente modules) |
| `base_config` | `{}` | extra Paladin config |
| `runtime_size` | `Small` | `ExtraSmall` \| `Small` \| `Medium` \| `Large` \| `ExtraLarge` |
| `runtime_zone` / `storage_size` / `storage_type` | `null` | runtime zone and storage; `null` uses platform defaults |
| `hostname` | `null` | publish the node's `jsonrpc`/`jsonrpcws` endpoints on this hostname |
| `read_registry_address` | `false` | set `true` on the registry-admin node only — reads back the deployed registry address |
| `network_registry` | `null` | the network module's `registry` output — plan-time validation that this node's role matches the network's registry config |

## Usage

```hcl
# Admin node — deploys the registry and reads back its address.
module "paladin_node_1" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-node?ref=main"

  environment_id          = var.environment_id
  network_id              = module.paladin_network.network_id
  stack_id                = module.paladin_network.stack_id
  node_name               = "node-1" # == registry_admin.node_name
  registry_admin_identity = "registry.admin"
  key_manager_service_id  = var.kms_id
  base_ledger             = { type = "local", gateway_service_id = var.gateway_id }
  wallets                 = { kms_key_store = "paladin-wallet" }
  domains                 = merge(module.noto.domain, module.pente.domain)
  read_registry_address   = true
  network_registry        = module.paladin_network.registry

  depends_on = [module.besu_node] # base ledger up before the registry deploy
}

# Joiner nodes — identical, minus read_registry_address, gated behind the admin.
module "paladin_node_2" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-node?ref=main"

  # … same settings, node_name = "node-2" …
  network_registry = module.paladin_network.registry

  depends_on = [module.paladin_node_1]
}
```

### Ordering (deploy mode)

The registry address is an output of this module, not the Paladin network module output: the
operator only deploys the registry contract via the admin node, after that node is up.
This is the correct deployment order:

1. **Base besu ledger** — the admin node depends the base ledger node.
2. **Admin before joiners** — admin node is the Paladin node made, and is responsible for bootstrapping the registry.
3. Set `read_registry_address = true` on the admin node and consume its
   `registry_address` output — e.g. as a joiner network's `existing_registry_address`.

`network_registry` needs to be passed to every node.

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `PaladinNodeService` |
| `runtime_id` | ID of the `PaladinNodeRuntime` |
| `node_name` | Display name of the node runtime and service |
| `endpoints` | Map of the node's published endpoints (`jsonrpc`, `jsonrpcws`, ...) |
| `hostnames` | Map of the node's hostnames |
| `registry_address` | Deployed EVM registry address (admin node with `read_registry_address = true` only; otherwise `null`) |
