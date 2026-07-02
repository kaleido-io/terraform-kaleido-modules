# Besu chaininfra stack with custom genesis

This Terraform example creates a `Besu` chain-infrastructure stack that is initialized
from a **custom genesis file** supplied by the caller, instead of letting the platform
bootstrap one automatically. It illustrates how you can own and manage your own
`genesis.json` and validator node key over the lifetime of the network.

> CAUTION: **Do not use the `nodekey` or `genesis` bundled in this sample for a production setup.**
> The private key in [`resources/nodekey`](./resources/nodekey) is committed to this repository
> in plaintext and is therefore public and compromised. Anyone can impersonate this validator.
> The pre-funded account in [`resources/genesis-with-fork.json`](./resources/genesis-with-fork.json)
> is likewise for demonstration only. For any real deployment, generate your own node key for the validator nodes and keep it in a secure location and use that nodekey to generate the extradata on the genesis file for the intial set of validators.

## Modules used

| Module | Role in this example |
|--------|----------------------|
| [`chaininfra-besu-network`](../../modules/chaininfra-besu-network) | The `BesuNetwork` and the `chain_infrastructure` stack, initialized in `manual` mode from [`resources/genesis-with-fork.json`](./resources/genesis-with-fork.json) |
| [`chaininfra-besu-node`](../../modules/chaininfra-besu-node) | Validator node(s) (seeded with the node key in [`resources/nodekey`](./resources/nodekey)) and RPC node(s) |
| [`chaininfra-evm-gateway`](../../modules/chaininfra-evm-gateway) | An EVM gateway for the network |
| [`chaininfra-block-indexer`](../../modules/chaininfra-block-indexer) | A block indexer wired to the gateway and a `ContractManager` service |

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
| `validator_count` | `1` | Number of validator nodes to deploy |
| `rpc_node_count` | `1` | Number of RPC nodes to deploy |

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
Create the environment, network, nodes, gateway, and block indexer:

```bash
terraform apply
```

### Update
Re-apply the example after editing inputs or the genesis to roll out changes to a running network:

```bash
terraform plan
terraform apply
```

#### Hardfork update

A common reason to own your genesis is to schedule an **EVM hardfork** at a future point rather
than activating everything at genesis. Fork activation is expressed in the genesis `config`
block — block-numbered forks (e.g. `berlinBlock`) and timestamp-based forks (e.g. `shanghaiTime`,
`osakaTime`).

The bundled [`resources/genesis-with-fork.json`](./resources/genesis-with-fork.json) demonstrates
this: Shanghai is active from genesis (`shanghaiTime: 0`) while Osaka is scheduled for a **future
Unix timestamp**:

```json
"config": {
  "berlinBlock": 0,
  "chainId": 5678,
  "shanghaiTime": 0,
  "osakaTime": 1783006559,
  "zeroBaseFee": true
}
```

Every node runs on the same genesis, so all nodes agree on when the fork activates and transition
in lockstep once the chain clock passes `osakaTime`.

To schedule (or bring forward) a hardfork on an already-running network:

**1. Edit the genesis file for fork activation**

Update the config field in the genesis file `resources/genesis-with-fork.json` (e.g. set `osakaTime` to a future timestamp that gives every node operator time to upgrade).

> NOTE: Always schedule timestamp-based forks comfortably in the future and coordinate the rollout across
> all validators and RPC nodes. Activating a fork in the past (or at a time that has already
> elapsed) can cause a chain split.

**2. Apply changes**

Run the following commands to update the deployment with these changes 

```hcl
terraform plan 
terraform apply
```
Because the module names the init file set by a hash of the genesis contents, changing the genesis rolls the file set and re-applies it to the network.

**3. Validate Updates**

Ensure all nodes are running a Besu version that supports the target fork **before** the activation time is reached, otherwise nodes on older versions will fork off the canonical chain.

### Destroy
Tear everything down again:

```bash
terraform destroy
```
