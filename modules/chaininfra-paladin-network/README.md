# chaininfra-paladin-network

Deploys a Paladin network (`kaleido_platform_network`, type `PaladinNetwork`) and the
`chain_infrastructure` stack (sub-type `PaladinStack`) that wraps it. The network's
registry of nodes is an EVM smart contract on the base ledger, in one of two modes:

- **`deploy`** (default) — the platform deploys a new registry contract. Requires
  `registry_admin`: the identity and node that perform the deployment. The named node
  must be created against this network with a matching `node_name`
  (see [chaininfra-paladin-node](../chaininfra-paladin-node)).
- **`existing`** — join a registry contract already deployed on the base ledger.
  Requires `existing_registry_address`.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the network and stack into |
| `network_name` | Display name of the `PaladinNetwork` |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `stack_name` | `network_name` | Display name of the chain-infrastructure stack |
| `registry_mode` | `deploy` | `deploy` deploys a new EVM registry contract; `existing` joins one already on the ledger |
| `registry_admin` | `null` | `{ identity, node_name }` that deploys/administers the registry — **required in `deploy` mode**; `node_name` must equal the admin node's `node_name` |
| `existing_registry_address` | `null` | Address of the already-deployed registry contract — **required in `existing` mode** |

## Usage

```hcl
module "paladin_network" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-network?ref=main"

  environment_id = kaleido_platform_environment.env.id
  network_name   = "asset-net"

  registry_mode  = "deploy"
  registry_admin = {
    identity  = "registry.admin"
    node_name = "node-1" # must match a chaininfra-paladin-node node_name on this network
  }
}
```

The deployed registry's address is not an output of this module: in `deploy` mode it
only exists after the admin node has run, so it is read back via the node module's
`read_registry_address` flag / `registry_address` output. In `existing` mode the caller
already has it.

## Outputs

| Output | Description |
|--------|-------------|
| `network_id` | ID of the `PaladinNetwork` — feeds `chaininfra-paladin-node` `network_id` |
| `stack_id` | ID of the chain-infrastructure stack — feeds `chaininfra-paladin-node` `stack_id` |
| `network_name` | Display name of the `PaladinNetwork` |
