# Paladin chaininfra stack with a Besu base ledger

This Terraform example creates a self-contained **Paladin** chain-infrastructure stack together
with everything it depends on: a Besu network that acts as the base ledger, the middleware used to
deploy the domain factory contracts, and a configurable number of Paladin nodes.

The Paladin network's node registry is an EVM contract deployed on the base ledger. By convention
the first node (`<node_name_prefix>-1`) is the registry node — it deploys the registry contract and
the platform submits every node's registration transactions through it.

The **noto** and **pente** domain factory contracts are built in ContractManager and deployed
through an EVM Connector standard API as idempotent workflow-engine transactions. The resulting
domain config is merged into every Paladin node, so all nodes share the same factories.

## Modules used

| Module | Role in this example |
|--------|----------------------|
| [`chaininfra-besu-network`](../../modules/chaininfra-besu-network) | The `BesuNetwork` and stack that serve as the Paladin base ledger |
| [`chaininfra-besu-node`](../../modules/chaininfra-besu-node) | A single validator node for the base ledger |
| [`chaininfra-evm-gateway`](../../modules/chaininfra-evm-gateway) | EVM gateway for the base ledger, used by the Paladin nodes and the EVM Connector |
| [`chaininfra-block-indexer`](../../modules/chaininfra-block-indexer) | Block indexer wired to the gateway and the `ContractManager` service, so domain contract calls decode |
| [`middleware-evm-connector`](../../modules/middleware-evm-connector) | EVM Connector whose standard API submits the idempotent domain factory deploys |
| [`chaininfra-paladin-domain-noto`](../../modules/chaininfra-paladin-domain-noto) | Builds and deploys the noto factory contracts and emits the `noto` domain config |
| [`chaininfra-paladin-domain-pente`](../../modules/chaininfra-paladin-domain-pente) | Builds and deploys the pente factory contracts and emits the `pente` domain config |
| [`chaininfra-paladin-network`](../../modules/chaininfra-paladin-network) | The `PaladinNetwork` and `PaladinStack`, with a new EVM registry deployed via node 1 (`registry_mode = "deploy"`) |
| [`chaininfra-paladin-node`](../../modules/chaininfra-paladin-node) | The Paladin nodes (`<prefix>-1` … `<prefix>-N`), each with its own KMS folder and the noto/pente domains |

## Additional resources

| Resource | Role in this example |
|----------|----------------------|
| `kaleido_platform_environment` | Environment to deploy into — only created when `environment_id` is empty |
| `kaleido_platform_runtime` / `kaleido_platform_service` (`KeyManager`) | Key Manager holding the Paladin node keys and the domain deployer key |
| `kaleido_platform_kms_wallet` | HD wallet (`paladin-wallet`) with a KMS folder per Paladin node |
| `kaleido_platform_kms_key` (`domain-deployer`) | Signing key used to deploy the noto and pente factory contracts |
| `kaleido_platform_runtime` / `kaleido_platform_service` (`ContractManager`) | Holds the domain contract builds for ABI visibility and block-indexer decoding |
| `kaleido_platform_runtime` / `kaleido_platform_service` (`WorkflowEngine`) | Required by the EVM Connector to run the idempotent deploy transactions |
| `kaleido_platform_evm_netinfo` (data source) | Reads the base ledger chain ID for the EVM Connector network metadata |

## Required settings

| Setting | Description |
|---------|-------------|
| `kaleido_platform_api` | Base URL of your Kaleido Platform API |
| `kaleido_platform_username` | Kaleido Platform API username |
| `kaleido_platform_password` | Kaleido Platform API password (sensitive) |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `environment_id` | `""` | ID of a pre-existing environment; leave empty to create a new one |
| `environment_name` | `paladin` | Name of the environment to create — only used when `environment_id` is empty |
| `network_name` | `paladin-network` | Name of the `PaladinNetwork` |
| `node_count` | `3` | Number of Paladin nodes to deploy; node 1 deploys the registry |
| `node_name_prefix` | `paladin-node` | Prefix for node names (`<prefix>-1` … `<prefix>-N`) |
| `publish_hostnames` | `false` | Publish each node's `jsonrpc`/`jsonrpcws` endpoints on a hostname named after the node |
| `besu_network_name` | `paladin-base` | Name of the Besu network used as the base ledger |
| `paladin_wallet_name` | `paladin-wallet` | Name of the KMS hdwallet backing the Paladin node keys |
| `paladin_repo` | `https://github.com/LFDT-Paladin/paladin` | Repository the domain contracts are sourced from — override to build from a fork |
| `paladin_ref` | pinned commit SHA | Git ref (branch or commit SHA) the domain contracts are sourced from |
| `domains` | `{}` | Additional Paladin domain config keyed by domain name, merged over the noto/pente domains |
| `signing_key_address` | `null` | Deploy signer for the domain factories as a `0x…` address, instead of the `domain-deployer` key |
| `signing_key_uri` | `null` | Deploy signer for the domain factories as a Key Manager key URI, instead of the `domain-deployer` key |

## Outputs

| Output | Description |
|--------|-------------|
| `network_id` / `stack_id` | IDs of the `PaladinNetwork` and its chain-infrastructure stack |
| `node_service_ids` | Service ID of each Paladin node, in node order |
| `node_endpoints` | Endpoints published by each Paladin node, in node order |
| `registry_address` | Address of the EVM registry contract deployed by node 1 |
| `noto_factory_address` / `pente_factory_address` | Addresses of the deployed domain factory contracts |

## Usage

To use this example make sure to create an `input.tfvars` from the example and provide all the required values

```bash
cp input.tfvars.example input.tfvars
```

### Initialize OpenTofu
Initialize the OpenTofu setup with the Kaleido provider and set up the working directory:

```bash
tofu init
```

### Review the plan
Inspect the resources that will be created before applying:

```bash
tofu plan --var-file=input.tfvars
```

### Apply
Create the environment, base ledger, middleware, domain factories, Paladin network, and nodes:

```bash
tofu apply --var-file=input.tfvars
```

The domains are deployed one at a time — noto first, then pente — because both submit through the
same signing key and EVM Connector. After apply, the factory addresses and the registry address are
available as outputs, and each node exposes its Paladin JSON-RPC endpoints.

### Update
Re-apply the example after editing inputs to roll out changes to a running deployment:

```bash
tofu plan --var-file=input.tfvars
tofu apply --var-file=input.tfvars
```

#### Add nodes

To grow the Paladin network after the initial deployment:

**1. Increase the node count**

Set `node_count` to the desired number of nodes in `input.tfvars`.

**2. Apply changes**

```bash
tofu plan --var-file=input.tfvars
tofu apply --var-file=input.tfvars
```

OpenTofu provisions an additional `chaininfra-paladin-node` for each new index, with its own KMS
folder under the shared hdwallet and the same noto/pente domain config as the existing nodes.

> NOTE: Node 1 is the registry node — the platform submits every node's registration transactions
> through it, so it must stay deployed and running for new nodes to join. Do not reduce `node_count`
> below `1`, and do not rename `node_name_prefix` on a running network.

> NOTE: The domain factory contracts live on the base ledger rather than on a specific Paladin
> network. If you point a second Paladin deployment at the same base ledger, run its domain modules
> in `join` or `join_with_builds` mode instead of deploying the factories again.

### Destroy
Tear everything down again:

```bash
tofu destroy --var-file=input.tfvars
```
