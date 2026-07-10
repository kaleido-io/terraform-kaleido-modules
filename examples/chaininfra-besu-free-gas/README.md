# Besu chaininfra stack with free gas

This Terraform example creates a `Besu` chain-infrastructure stack where transactions do not
incur a base fee. The network is bootstrapped automatically by the platform in `automated` init
mode with `zeroBaseFee` enabled (the `chaininfra-besu-network` module default), so contract calls
and transfers can be submitted without gas cost.

The example also deploys a **Blockchain Application Firewall (BAF)** with a sample Rego policy
that restricts which JSON-RPC methods and signer addresses may use the BAF gateway.

## Modules used

| Module | Role in this example |
|--------|----------------------|
| [`chaininfra-besu-network`](../../modules/chaininfra-besu-network) | The `BesuNetwork` and the `chain_infrastructure` stack, bootstrapped automatically with QBFT consensus and `zeroBaseFee` enabled |
| [`chaininfra-besu-node`](../../modules/chaininfra-besu-node) | Validator node(s) and RPC node(s) joined to the network |
| [`chaininfra-evm-gateway`](../../modules/chaininfra-evm-gateway) | An EVM gateway for the network |
| [`chaininfra-block-indexer`](../../modules/chaininfra-block-indexer) | A block indexer wired to the gateway and a `ContractManager` service |
| [`chaininfra-baf`](../../modules/chaininfra-baf) | A BAF stack with a sample access-control policy attached to a Kaleido application |

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
| `validator_count` | `1` | Number of validator nodes to deploy |
| `rpc_node_count` | `1` | Number of RPC nodes to deploy |
| `baf_enabled` | `true` | Whether to deploy the Blockchain Application Firewall |
| `baf_policies` | sample policy | List of BAF policies (`file` path and Kaleido `application` name) |

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
Create the environment, network, nodes, gateway, block indexer, and BAF stack:

```bash
terraform apply
```

### Update
Re-apply the example after editing inputs to roll out changes to a running deployment:

```bash
terraform plan
terraform apply
```

#### BAF policy update

The bundled [`resources/sample-baf-policy`](./resources/sample-baf-policy) demonstrates fine-grained
gateway permissions using Rego. This example contains a sample policy that allows only `eth_call` and `eth_sendRawTransaction`,
and restricts `eth_sendRawTransaction` to a specific `from` address. To apply changes to the policies follow the steps below

**1. Edit the policy**

Update the Rego source in `resources/sample-baf-policy` — for example, change the allowed methods
or replace the hard-coded signer address with addresses relevant to your application.

**2. Apply changes**

```bash
terraform plan
terraform apply
```

The `chaininfra-baf` module re-attaches the updated policy to the BAF gateway on apply.

### Destroy
Tear everything down again:

```bash
terraform destroy
```
