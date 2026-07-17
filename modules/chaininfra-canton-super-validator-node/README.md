# chaininfra-canton-super-validator-node

Deploys a single Canton super validator node (`CantonSuperValidatorNode` runtime +
service) into an existing validator-network stack. The super validator manages
governance operations on a `Sandbox` validator network.

## Required settings

| Setting | Description |
|-----------|-------------|
| `environment_id` | Kaleido environment to deploy the node into |
| `network_id` | [`network_id`](../chaininfra-canton-validator-network#outputs) from [`chaininfra-canton-validator-network`](../chaininfra-canton-validator-network) — the `CantonValidator` network this node joins |
| `stack_id` | [`stack_id`](../chaininfra-canton-validator-network#outputs) from [`chaininfra-canton-validator-network`](../chaininfra-canton-validator-network) — the `CantonStack` the runtime and service belong to |
| `default_party` | Default Canton party ID operated by this super validator |
| `kms_id` | ID of the `KeyManager` service that holds node keys |
| `kms_wallet_name` | Name of the KMS wallet within the KeyManager where keys are stored |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `node_name` | `local-super-validator-node` | Display name of the runtime and service |
| `runtime_size` | `Medium` | Runtime size (`Medium`, `Large`, or `ExtraLarge`) |
| `zone` | `null` | Deployment zone; `null` uses the platform default |
| `subzone` | `null` | Subzone within the zone; `null` lets the scheduler choose |
| `storage_type` | `null` | Persistent-volume storage class; `null` uses the platform default |
| `storage_size` | `null` | Persistent-volume size in GB; `null` uses the platform default |
| `kms_wallet_folder` | `null` | Subfolder under the KMS wallet for this node's keys; defaults to `node_name` when unset |
| `kms_key_spec` | `secp256r1` | Curve for node keys (`secp256r1` or `secp256k1`) |
| `node_key` | `null` | Base64-encoded secp256r1 private key for the node identity; platform-generated when unset |
| `hostname_prefix` | `super-validator` | Prefix for custom hostnames; publishes `ledger` and `admin` endpoints |

## Usage

Create a Canton super validator node for the Sandbox network. The super validator node is responsible for network governance and upgrades and initializes the network.

```hcl
module "validator_network" {
  source = "../../modules/chaininfra-canton-validator-network"

  environment_id = kaleido_platform_environment.env.id
  network_type   = "Sandbox"
}

module "super_validator" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-canton-super-validator-node?ref=main"

  environment_id  = kaleido_platform_environment.env.id
  network_id      = module.validator_network.network_id
  stack_id        = module.validator_network.stack_id
  default_party   = "sandbox-sv"
  kms_id          = kaleido_platform_service.kms.id
  kms_wallet_name = kaleido_platform_kms_wallet.canton.name
  runtime_size    = "Large"
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `CantonSuperValidatorNode` service |
| `runtime_id` | ID of the `CantonSuperValidatorNode` runtime |
| `endpoints` | Map of published service endpoints |
| `hostnames` | Map of custom hostnames bound to the service |
