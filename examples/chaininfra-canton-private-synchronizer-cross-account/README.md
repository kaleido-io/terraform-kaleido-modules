# Canton chaininfra stack with private synchronizer (cross-account)

This Terraform example creates a **private Canton synchronizer spanning two Kaleido
accounts**. Account 1 hosts the local synchronizer network and node (sequencer and
mediator) plus participant `alice`. Account 2 hosts participant `bob` and joins the
same synchronizer through a pair of platform network connectors (requestor on account 1,
acceptor on account 2).

Each account has its own environment, Key Manager, and KMS wallet. Modules are bound to
the correct account with the Terraform `providers` meta-argument mapping the module's
default `kaleido` provider to the aliased `kaleido.account_1` or `kaleido.account_2`
instance declared in `providers.tf`.

## Architecture

| Account | What it deploys |
|---------|-----------------|
| **Account 1** | Environment, Key Manager, local synchronizer network + stack (`init_mode = "manual"`), synchronizer node, participant `alice`, platform connector (**requestor**) |
| **Account 2** | Environment, Key Manager, synchronizer network + stack (`init_mode = "automated"`), participant `bob`, platform connector (**acceptor**) linking back to account 1's connector |

The connectors wire the two accounts together so `alice` and `bob` can participate in
multi-party workflows on the shared private synchronizer.

### Synchronizer network init mode

Init mode differs by role in the cross-account topology:

| Network | `init_mode` | Why |
|---------|-------------|-----|
| Account 1 (host) | `manual` | This account creates the synchronizer **node** (sequencer and mediator). The node initializes the network. |
| Account 2 and any subsequent joining accounts | `automated` (module default) | These accounts do **not** create synchronizer nodes. They only create a synchronizer network object and connect to the existing host synchronizer through platform connectors. |

Leave `init_mode` unset (or set it explicitly to `automated`) on every joining network. Using `manual` on a joining network without a local synchronizer node leaves that network uninitialized.

## Modules used

| Module | Role in this example |
|--------|----------------------|
| [`chaininfra-canton-synchronizer-network`](../../modules/chaininfra-canton-synchronizer-network) | `CantonSynchronizer` network and `CantonStack` in each account — `manual` on the host (account 1), `automated` on joining accounts |
| [`chaininfra-canton-synchronizer-node`](../../modules/chaininfra-canton-synchronizer-node) | Synchronizer node (sequencer and mediator) hosted in account 1 |
| [`chaininfra-canton-participant-node`](../../modules/chaininfra-canton-participant-node) | Participant `alice` (account 1) and `bob` (account 2), each connected to their account's synchronizer network |

## Additional resources

| Resource | Role in this example |
|----------|----------------------|
| `kaleido_platform_account` (data) | Resolves each account's ID for the connector `target_account_id` fields |
| `kaleido_platform_runtime` / `kaleido_platform_service` (`KeyManager`) | Per-account Key Manager for Canton signing keys |
| `kaleido_platform_kms_wallet` | Per-account Kaleido keystore wallet (`canton`) |
| `kaleido_network_connector` | Platform connectors linking the two synchronizer networks (requestor ↔ acceptor) |

## Required settings

Credentials for **both** Kaleido accounts and a connector zone must be supplied:

| Setting | Description |
|---------|-------------|
| `kaleido_platform_api_account_1` | Base URL of the Kaleido Platform API for account 1 |
| `kaleido_platform_username_account_1` | API username for account 1 |
| `kaleido_platform_password_account_1` | API password for account 1 (sensitive) |
| `kaleido_platform_api_account_2` | Base URL of the Kaleido Platform API for account 2 |
| `kaleido_platform_username_account_2` | API username for account 2 |
| `kaleido_platform_password_account_2` | API password for account 2 (sensitive) |
| `platform_connector_zone` | Deployment zone for the platform network connectors |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `environment_name` | `canton-chain-infra` | Name of the environment created in each account |
| `synchronizer_network_name` | `canton-synchronizer` | Display name of the `CantonSynchronizer` network in each account |
| `kms_wallet_type` | `kaleidokeystore` | KMS wallet type for each account's Canton wallet |
| `kms_key_spec` | `secp256r1` | Curve for Canton node and party keys (`secp256r1` or `secp256k1`) |

## Usage

To use this example make sure to create a `terraform.tfvars` from the example and provide all the required values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

```hcl
kaleido_platform_api_account_1      = "https://<account-1>.kaleido.dev/"
kaleido_platform_username_account_1 = "<account-1-username>"
kaleido_platform_password_account_1 = "<account-1-password>"

kaleido_platform_api_account_2      = "https://<account-2>.kaleido.dev/"
kaleido_platform_username_account_2 = "<account-2-username>"
kaleido_platform_password_account_2 = "<account-2-password>"

platform_connector_zone = "<your-connector-zone>"
```

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
Create both accounts' environments, Key Managers, synchronizer networks, the account 1
synchronizer node, participants, and the requestor/acceptor connectors:

```bash
terraform apply
```

After apply, account 1 runs the synchronizer node and participant `alice`; account 2 runs
participant `bob`. The platform connectors link the two synchronizer networks so both
participants share the private synchronizer.

### Update
Re-apply the example after editing inputs to roll out changes to a running deployment:

```bash
terraform plan
terraform apply
```

#### Add a participant in either account

To onboard another party, add a `chaininfra-canton-participant-node` module and bind it
to the correct account with `providers`:

**1. Add a participant module (example: account 2)**

```hcl
module "chaininfra-canton-participant-node-account-2-charlie" {
  source = "../../modules/chaininfra-canton-participant-node"
  providers = {
    kaleido = kaleido.account_2
  }

  environment_id = kaleido_platform_environment.account_2_env.id
  stack_id       = module.chaininfra-canton-synchronizer-network-account-2.stack_id
  default_party  = "charlie"
  kms_key_spec   = var.kms_key_spec

  synchronizer_network_ids = [module.chaininfra-canton-synchronizer-network-account-2.network_id]
  kms_id                   = kaleido_platform_service.account_2_kms.id
  kms_wallet_name          = kaleido_platform_kms_wallet.account_2_kms_wallet.name
}
```

For account 1, use `kaleido.account_1` and the account 1 environment / network / KMS
references instead.

**2. Apply changes**

```bash
terraform plan
terraform apply
```

> NOTE: Always pass `providers = { kaleido = kaleido.account_N }` on modules that should
> run in a specific account. Omitting it causes the module to use the default provider,
> which is undefined in this example (only aliased providers are configured).

### Destroy
Tear everything down again:

```bash
terraform destroy
```
