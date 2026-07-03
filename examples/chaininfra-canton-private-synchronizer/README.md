# Canton chaininfra stack with private synchronizer

This Terraform example creates a self-contained Canton chain-infrastructure stack built
around a **private (local) synchronizer**. The platform bootstraps a `CantonSynchronizer`
network, deploys a synchronizer node (sequencer and mediator), and provisions two participant
nodes (`alice` and `bob`) that connect to the same synchronizer for multi-party workflows.

A shared **Key Manager** service holds Canton signing keys for the synchronizer node and both
participants in a single KMS wallet.

## Modules used

| Module | Role in this example |
|--------|----------------------|
| [`chaininfra-canton-synchronizer-network`](../../modules/chaininfra-canton-synchronizer-network) | The `CantonSynchronizer` network and `CantonStack` wrapping it (`Local` synchronizer, `stack_enabled = true`) |
| [`chaininfra-canton-synchronizer-node`](../../modules/chaininfra-canton-synchronizer-node) | Synchronizer node running the sequencer and mediator for the private synchronizer network |
| [`chaininfra-canton-participant-node`](../../modules/chaininfra-canton-participant-node) | Participant nodes for `alice` and `bob`, each connected to the synchronizer network |

## Additional resources

| Resource | Role in this example |
|----------|----------------------|
| `kaleido_platform_runtime` (`KeyManager`) | Runtime for the Key Manager service |
| `kaleido_platform_service` (`KeyManager`) | Key Manager service used to create and hold Canton signing keys |
| `kaleido_platform_kms_wallet` | Kaleido keystore wallet (`canton`) shared by the synchronizer node and participant nodes |

## Required settings

| Setting | Description |
|---------|-------------|
| `kaleido_platform_api` | Base URL of your Kaleido Platform API |
| `kaleido_platform_username` | Kaleido Platform API username |
| `kaleido_platform_password` | Kaleido Platform API password (sensitive) |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `environment_name` | `canton-chain-infra` | Name of the environment to create |
| `synchronizer_network_name` | `canton-synchronizer` | Display name of the `CantonSynchronizer` network |
| `kms_wallet_type` | `kaleidokeystore` | KMS wallet type for the shared Canton wallet |
| `kms_key_spec` | `secp256r1` | Curve for Canton node and party keys (`secp256r1` or `secp256k1`) |

## Usage

To use this example make sure to create a `terraform.tfvars` from the example and provide all the required values

### Initialize Terraform
Initialize the terraform setup with the Kaleido terraform provider and set up the working directory:

```bash
terraform init
```

### Review the plan
Inspect the resources that will be created before applying:

```bash
terraform plan
```

### Apply
Create the environment, Key Manager, synchronizer network, synchronizer node, and participant nodes:

```bash
terraform apply
```

After apply, the synchronizer node exposes sequencer and mediator endpoints, and each
participant (`alice`, `bob`) publishes ledger, admin, and HTTP endpoints scoped to its party.

### Update
Re-apply the example after editing inputs to roll out changes to a running deployment:

```bash
terraform plan
terraform apply
```

#### Add participants

To onboard additional participants onto the same private synchronizer, add another
`chaininfra-canton-participant-node` module block following the `alice` / `bob` pattern in
`main.tf`:

**1. Add a participant module**

```hcl
module "chaininfra-canton-participant-node-charlie" {
  source = "../../modules/chaininfra-canton-participant-node"

  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.chaininfra-canton-synchronizer-network.stack_id
  default_party  = "charlie"
  kms_key_spec   = var.kms_key_spec

  synchronizer_network_ids = [module.chaininfra-canton-synchronizer-network.network_id]
  kms_id                   = kaleido_platform_service.kms.id
  kms_wallet_name          = kaleido_platform_kms_wallet.kms_wallet.name
}
```

**2. Apply changes**

```bash
terraform plan
terraform apply
```

Each participant receives its own KMS wallet folder (defaulting to `participant-<party>`) and
connects to the shared synchronizer network for ledger synchronization.

### Destroy
Tear everything down again:

```bash
terraform destroy
```
