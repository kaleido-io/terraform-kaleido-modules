# chaininfra-besu-node

Deploys a single Besu node (`BesuNode` runtime + service) into an existing
chain-infrastructure stack and Besu network.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the node into |
| `stack_id` | [`stack_id`](../chaininfra-besu-network#outputs) from [`chaininfra-besu-network`](../chaininfra-besu-network) — chain-infrastructure stack the node belongs to |
| `network_id` | [`network_id`](../chaininfra-besu-network#outputs) from [`chaininfra-besu-network`](../chaininfra-besu-network) — `BesuNetwork` the node joins |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `node_name` | `besu-node` | Display name of the runtime and service |
| `runtime_size` | `null` | Runtime size (`ExtraSmall`–`ExtraLarge`); `null` uses the platform default |
| `zone` | `null` | Deployment zone; `null` uses the platform default |
| `subzone` | `null` | Subzone within the zone; `null` lets the scheduler choose |
| `storage_type` | `null` | Persistent-volume storage class; `null` uses the platform default |
| `storage_size` | `null` | Persistent-volume size in GB; `null` uses the platform default |
| `signer` | `false` | Whether the node is a network signer/validator |
| `mode` | `active` | `active` receives RPC requests; `standby` does not |
| `routable` | `true` | Whether the node is eligible as a gateway backend |
| `sync_mode` | `FULL` | Blockchain sync mode (`FULL` archive or `SNAP`) |
| `log_level` | `INFO` | Besu runtime log level |
| `data_storage_format` | `BONSAI` | Database storage format (`BONSAI` or `FOREST`) |
| `apis_enabled` | `["TRACE"]` | Additional Besu APIs beyond the always-on set |
| `custom_besu_args` | `["--revert-reason-enabled"]` | Extra Besu command-line arguments |
| `target_gas_limit` | `null` | Per-transaction gas limit cap; `null` uses the platform default |
| `gas_price` | `"0"` | Gas price for transactions |
| `genesis_json` | `null` | Node-specific genesis override for externally managed networks |
| `node_key` | `null` | secp256k1 private key for the node identity; platform-generated when unset (sensitive) |

## Usage

### Besu Validator

Create a Besu validator node which signs blocks and takes part in maintaining consensus for the network
```hcl
module "besu_signer" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-besu-node?ref=main"

  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.besu_network.stack_id
  network_id     = module.besu_network.network_id
  node_name      = "besu-signer-1"
  signer         = true
}
```
### Bring your own validator key
Create a Besu validator node with the known node private key so that you can own and manager the private keys for the validator set.

```hcl
module "besu_signer" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-besu-node?ref=main"

  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.besu_network.stack_id
  network_id     = module.besu_network.network_id
  node_name      = "besu-signer-1"
  signer         = true
  node_key       = file(PATH_TO_PRIVATE_KEY)
}
```

### Besu Peer

Create a Besu RPC nodes that can be used to submit transactions to the network and is connected to other peers and validators of the network.
```

module "besu_peer" {
  source = "../../modules/chaininfra-besu-node"

  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.besu_network.stack_id
  network_id     = module.besu_network.network_id
  node_name      = "besu-peer-1"
  runtime_size   = "Medium"
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `BesuNode` service |
| `runtime_id` | ID of the `BesuNode` runtime |
| `node_name` | Display name of the runtime and service |
| `connectivity_json` | Peer connectivity descriptor for building network connectors |
| `endpoints` | Map of published service endpoints |
| `hostnames` | Map of custom hostnames bound to the service |
