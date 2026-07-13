# chaininfra-paladin-network

Deploys a Paladin network (`PaladinNetwork`) and the `chain_infrastructure` stack
(`PaladinStack`) on the Kaleido platform. The network's node registry is an EVM contract on
the base ledger, deployed or joined per `registry_mode`.

## Modes

| `registry_mode` | Behavior |
|---|---|
| `deploy` (default) | platform deploys a new registry contract via the registry node, rootless (no identity owns it) — requires `registry_node` |
| `existing` | join a registry contract already on the base ledger — requires `existing_registry_address` |

## Settings

| Setting | Default | Usage |
|---------|---------|-------|
| `environment_id` | required | Kaleido environment to create resources in |
| `network_name` | required | name of the `PaladinNetwork` |
| `stack_name` | `network_name` | name of the chain-infrastructure stack |
| `registry_mode` | `deploy` | `deploy` deploys a new EVM registry contract; `existing` joins one |
| `registry_node` | `null` | name of the PaladinNodeService that deploys the registry (by convention the first node) — **required in `deploy` mode**; must match that node's `node_name` |
| `existing_registry_address` | `null` | registry contract address — **required in `existing` mode** |

## Usage

```hcl
module "paladin_network" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-network?ref=main"

  environment_id = kaleido_platform_environment.env.id
  network_name   = "asset-net"

  registry_mode = "deploy"
  registry_node = "node-1" # must match a chaininfra-paladin-node node_name on this network
}
```

In `deploy` mode the registry address is read from the `registry_address` terraform output of the registry node.

## Outputs

| Output | Description |
|--------|-------------|
| `network_id` | Paladin network ID — feeds `chaininfra-paladin-node` `network_id` |
| `stack_id` | Chain-infrastructure stack ID — feeds `chaininfra-paladin-node` `stack_id` |
| `network_name` | Name of the `PaladinNetwork` |
| `registry` | `{ mode, registry_node }` — feed to each node's `network_registry` for plan-time validation |
