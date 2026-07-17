# Besu chaininfra stack with gas

This Terraform example creates a `Besu` chain-infrastructure stack where transactions incur gas
fees. The network is bootstrapped automatically in `automated` init mode with `zeroBaseFee` disabled,
so callers must hold a funded account to pay for transactions.

A **Key Manager** service is provisioned and its Ethereum address is pre-funded in the genesis
block via `initial_balances`, giving you a ready-to-use account for signing and submitting
gas-paying transactions.

## Modules used

| Module | Role in this example |
|--------|----------------------|
| [`chaininfra-besu-network`](../../modules/chaininfra-besu-network) | The `BesuNetwork` and the `chain_infrastructure` stack, bootstrapped with `zeroBaseFee = false` and an `initial_balances` entry for the Key Manager fund-holder address |
| [`chaininfra-besu-node`](../../modules/chaininfra-besu-node) | Validator node(s) and RPC node(s) joined to the network |
| [`chaininfra-evm-gateway`](../../modules/chaininfra-evm-gateway) | An EVM gateway for the network |
| [`chaininfra-block-indexer`](../../modules/chaininfra-block-indexer) | A block indexer wired to the gateway and a `ContractManager` service |

## Additional resources

| Resource | Role in this example |
|----------|----------------------|
| `kaleido_platform_runtime` (`KeyManager`) | Runtime for the Key Manager service |
| `kaleido_platform_service` (`KeyManager`) | Key Manager service used to create and hold signing keys |
| `kaleido_platform_kms_wallet` | Kaleido keystore wallet (`wallet`) scoped to the Key Manager service |
| `kaleido_platform_kms_key` (`fund-holder-key`) | Ethereum signing key whose address is pre-funded in the genesis block via `initial_balances` |

## Required settings

| Setting | Description |
|---------|-------------|
| `kaleido_platform_api` | Base URL of your Kaleido Platform API |
| `kaleido_platform_username` | Kaleido Platform API username |
| `kaleido_platform_password` | Kaleido Platform API password (sensitive) |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `environment_name` | `besu-chain-infra` | Name of the environment to create |
| `network_name` | `besu` | Display name of the `BesuNetwork` |
| `stack_name` | `besu` | Display name of the chain-infrastructure stack |
| `chain_id` | `12345` | Network chain ID |
| `fund_holder_balance` | `0x111111111111` | Wei balance allocated to the Key Manager fund-holder address in the genesis block |
| `validator_count` | `1` | Number of validator nodes to deploy |
| `rpc_node_count` | `1` | Number of RPC nodes to deploy |
| `baf_enabled` | `false` | Whether to deploy the Blockchain Application Firewall |
| `baf_policies` | `[]` | List of BAF policies (`file` path and `application_id`) when BAF is enabled |

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
Create the environment, Key Manager, network, nodes, gateway, and block indexer:

```bash
terraform apply
```

After apply, the Key Manager fund-holder key (`fund-holder-key`) holds the genesis balance and can
be used to sign transactions that pay gas on the network.

### Update
Re-apply the example after editing inputs to roll out changes to a running deployment:

```bash
terraform plan
terraform apply
```

#### Scale validators

To grow the validator set after the initial deployment:

**1. Increase the validator count**

Set `validator_count` to the desired number of validators in `terraform.tfvars`.

**3. Apply changes**

```bash
terraform plan
terraform apply
```

Terraform provisions additional `chaininfra-besu-node` instances for each new validator index.

> NOTE: `fund_holder_balance` is written into the genesis at network creation time. Changing it on
> an already-running network does not retroactively alter on-chain balances — adjust allocations
> through transactions instead.

### Destroy
Tear everything down again:

```bash
terraform destroy
```
