# chaininfra-canton-participant-node

Deploys a single Canton participant node (`CantonParticipantNode` runtime + service)
into an existing chain-infrastructure stack for Canton. A participant node
can connect to exactly one canton validator network and optionally connect to one or more canton synchronizer networks

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the node into |
| `stack_id` | [`stack_id`](../chaininfra-canton-validator-network#outputs) from [`chaininfra-canton-validator-network`](../chaininfra-canton-validator-network) or [`stack_id`](../chaininfra-canton-synchronizer-network#outputs) from [`chaininfra-canton-synchronizer-network`](../chaininfra-canton-synchronizer-network) — the `CantonStack` hosting the participant |
| `default_party` | Default Canton party ID operated by this participant |
| `kms_id` | ID of the `KeyManager` service that holds party and node keys |
| `kms_wallet_name` | Name of the KMS wallet within the KeyManager where keys are stored |
| `kms_wallet_folder` | Subfolder under the KMS wallet for this node's keys |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `node_name` | `local-synchronizer-node` | Display name of the runtime and service |
| `validator_network_id` | `null` | [`network_id`](../chaininfra-canton-validator-network#outputs) from [`chaininfra-canton-validator-network`](../chaininfra-canton-validator-network) — validator network to join |
| `synchronizer_network_ids` | `[]` | List of [`network_id`](../chaininfra-canton-synchronizer-network#outputs) values from [`chaininfra-canton-synchronizer-network`](../chaininfra-canton-synchronizer-network) — synchronizer networks to join |
| `runtime_size` | `null` | Runtime size (`ExtraSmall`–`ExtraLarge`); `null` uses the platform default |
| `zone` | `null` | Deployment zone; `null` uses the platform default |
| `subzone` | `null` | Subzone within the zone; `null` lets the scheduler choose |
| `storage_type` | `null` | Persistent-volume storage class; `null` uses the platform default |
| `storage_size` | `null` | Persistent-volume size in GB; `null` uses the platform default |
| `kms_key_spec` | `secp256r1` | Curve for node keys (`secp256r1` or `secp256k1`) |
| `hostname_prefix` | `participant` | Prefix for custom hostnames; publishes `ledger`, `admin`, and `http-ledger` / `node` / `validator` endpoints |
| `onboarding_secret` | `null` | Onboarding secret for `Testnet` and `Mainnet` validator-network join (sensitive) |

## Usage

### Participant Node with Canton Sandbox
Create a Canton Participant node connected to a Canton Sandbox network and a Canton Synchronizer network

```hcl
module "validator_network" {
  source = "../../modules/chaininfra-canton-validator-network"

  environment_id = kaleido_platform_environment.env.id
  network_type   = "Sandbox"
}

module "synchronizer_network" {
  source = "../../modules/chaininfra-canton-synchronizer-network"

  environment_id = kaleido_platform_environment.env.id
  network_name   = "local-synchronizer"
}

module "participant" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-canton-participant-node?ref=main"

  environment_id           = kaleido_platform_environment.env.id
  stack_id                 = module.validator_network.stack_id
  default_party            = "sandbox-participant"
  kms_id                   = kaleido_platform_service.kms.id
  kms_wallet_name          = kaleido_platform_kms_wallet.canton.name
  kms_wallet_folder        = "canton-sandbox"
  validator_network_id     = module.validator_network.network_id
  synchronizer_network_ids = [module.synchronizer_network.network_id]
}
```

### Participant node with Canton Testnet
Create a Canton Participant node connected to the Canton Testnet. Onboarding secret is only required when the participant node is connected to the `Testnet` or the `Mainnet`
```
module "validator_network" {
  source = "../../modules/chaininfra-canton-validator-network"

  environment_id = kaleido_platform_environment.env.id
  network_type   = "Testnet"

}

module "participant_testnet" {
  source = "../../modules/chaininfra-canton-participant-node"

  environment_id       = kaleido_platform_environment.env.id
  stack_id             = module.validator_network.stack_id
  default_party        = "my-party"
  kms_id               = kaleido_platform_service.kms.id
  kms_wallet_name      = kaleido_platform_kms_wallet.canton.name
  kms_wallet_folder    = "canton-testnet"
  validator_network_id = module.validator_network.network_id
  onboarding_secret    = file("${path.module}/onboarding-secret")
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `CantonParticipantNode` service |
| `runtime_id` | ID of the `CantonParticipantNode` runtime |
| `endpoints` | Map of published service endpoints |
| `hostnames` | Map of custom hostnames bound to the service |
