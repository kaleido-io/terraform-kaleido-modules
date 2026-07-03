# Canton chaininfra stack with sandbox network

This Terraform example creates a self-contained Canton chain-infrastructure stack built
around a **Sandbox validator network**. The sandbox emulates the Global Synchronizer locally
with Canton coins enabled, making it suitable for development and testing without joining
Testnet or Mainnet.

The example deploys a super validator node (`alice`) that initializes and governs the sandbox
network, and a participant node (`bob`) that connects to the validator network for ledger
operations. A shared **Key Manager** service holds Canton signing keys for both nodes in a
single KMS wallet.

## Modules used

| Module | Role in this example |
|--------|----------------------|
| [`chaininfra-canton-validator-network`](../../modules/chaininfra-canton-validator-network) | The `CantonValidator` sandbox network and `CantonStack` wrapping it (`network_type = "Sandbox"`) |
| [`chaininfra-canton-super-validator-node`](../../modules/chaininfra-canton-super-validator-node) | Super validator node (`alice`) responsible for sandbox network governance and initialization |
| [`chaininfra-canton-participant-node`](../../modules/chaininfra-canton-participant-node) | Participant node (`bob`) connected to the sandbox validator network |

## Additional resources

| Resource | Role in this example |
|----------|----------------------|
| `kaleido_platform_runtime` (`KeyManager`) | Runtime for the Key Manager service |
| `kaleido_platform_service` (`KeyManager`) | Key Manager service used to create and hold Canton signing keys |
| `kaleido_platform_kms_wallet` | Kaleido keystore wallet (`canton-sandbox`) shared by the super validator and participant nodes |

## Required settings

| Setting | Description |
|---------|-------------|
| `kaleido_platform_api` | Base URL of your Kaleido Platform API |
| `kaleido_platform_username` | Kaleido Platform API username |
| `kaleido_platform_password` | Kaleido Platform API password (sensitive) |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `environment_name` | `canton-sandbox` | Name of the environment to create |
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
Create the environment, Key Manager, sandbox validator network, super validator node, and participant node:

```bash
terraform apply
```

After apply, the super validator (`alice`) publishes ledger and admin endpoints for network
governance, and the participant (`bob`) publishes ledger, admin, and HTTP endpoints for
application workflows on the sandbox network.

### Update
Re-apply the example after editing inputs to roll out changes to a running deployment:

```bash
terraform plan
terraform apply
```

#### Add participants

To onboard additional parties onto the same sandbox network, add another
`chaininfra-canton-participant-node` module block following the `bob` pattern in `main.tf`:

**1. Add a participant module**

```hcl
module "chaininfra-canton-participant-node-charlie" {
  source = "../../modules/chaininfra-canton-participant-node"

  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.chaininfra-canton-validator-network.stack_id
  default_party  = "charlie"
  kms_key_spec   = var.kms_key_spec

  validator_network_id = module.chaininfra-canton-validator-network.network_id
  kms_id               = kaleido_platform_service.kms.id
  kms_wallet_name      = kaleido_platform_kms_wallet.kms_wallet.name
}
```

**2. Apply changes**

```bash
terraform plan
terraform apply
```

Each participant receives its own KMS wallet folder (defaulting to `participant-<party>`) and
connects to the sandbox validator network for ledger synchronization.

> NOTE: The super validator node must be running before participants can operate on the sandbox
> network. Do not remove or replace the super validator on an initialized sandbox without
> understanding the governance implications.

### Destroy
Tear everything down again:

```bash
terraform destroy
```
