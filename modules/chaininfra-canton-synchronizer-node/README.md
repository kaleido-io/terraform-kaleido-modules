# chaininfra-canton-synchronizer-node

Deploys a single Canton synchronizer node (`CantonSynchronizerNode` runtime + service)
that runs the sequencer and mediator for a synchronizer network.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the node into |
| `network_id` | [`network_id`](../chaininfra-canton-synchronizer-network#outputs) from [`chaininfra-canton-synchronizer-network`](../chaininfra-canton-synchronizer-network) — the `CantonSynchronizer` network this node joins |
| `stack_id` | [`stack_id`](../chaininfra-canton-synchronizer-network#outputs) from [`chaininfra-canton-synchronizer-network`](../chaininfra-canton-synchronizer-network) — the `CantonStack` the runtime and service belong to (`null` when the network was created with `stack_enabled = false`) |
| `kms_id` | ID of the `KeyManager` service that holds node keys |
| `kms_wallet_name` | Name of the KMS wallet within the KeyManager where keys are stored |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `node_name` | `local-synchronizer-node` | Display name of the runtime and service |
| `runtime_size` | `null` | Runtime size (`ExtraSmall`–`ExtraLarge`); `null` uses the platform default |
| `zone` | `null` | Deployment zone; `null` uses the platform default |
| `subzone` | `null` | Subzone within the zone; `null` lets the scheduler choose |
| `storage_type` | `null` | Persistent-volume storage class; `null` uses the platform default |
| `storage_size` | `null` | Persistent-volume size in GB; `null` uses the platform default |
| `kms_wallet_folder` | `null` | Subfolder under the KMS wallet for this node's keys; defaults to `node_name` when unset |
| `kms_key_spec` | `secp256r1` | Curve for node keys (`secp256r1` or `secp256k1`) |
| `hostname_prefix` | `synchronizer` | Prefix for custom hostnames; publishes `sequencer`, `sequencer-admin`, and `mediator` endpoints |

## Usage

```hcl
module "synchronizer_network" {
  source = "../../modules/chaininfra-canton-synchronizer-network"

  environment_id = kaleido_platform_environment.env.id
  network_name   = "local-synchronizer"
}

module "synchronizer_node" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-canton-synchronizer-node?ref=main"

  environment_id  = kaleido_platform_environment.env.id
  network_id      = module.synchronizer_network.network_id
  stack_id        = module.synchronizer_network.stack_id
  kms_id          = kaleido_platform_service.kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.canton.name
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `CantonSynchronizerNode` service |
| `runtime_id` | ID of the `CantonSynchronizerNode` runtime |
| `endpoints` | Map of published service endpoints |
| `hostnames` | Map of custom hostnames bound to the service |
