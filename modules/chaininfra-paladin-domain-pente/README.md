# chaininfra-paladin-pente

Registers the **pente** domain for a Paladin network: builds and deploys the pente
factory contracts (once per base ledger), and emits a `domain` config
fragment for [chaininfra-paladin-node](../chaininfra-paladin-node)'s `domains`
variable (every node).

Deploys are submitted through an EVM Connector's standard API as idempotent
workflow-engine transactions — each deploy resource only ever submits one unique
transaction. Deployment records live in the connector's transactions API, not in
ContractManager (builds remain in CMS for ABI visibility / block-indexer decoding).

## Modes

The factory contracts live on the base ledger, not on a specific Paladin network's
registry, so only one call of this module per base ledger should deploy them — other
calls (e.g. a second Paladin network sharing the same base ledger) just reference the
already-deployed factory.

| `mode` | Behavior |
|--------|----------|
| `deploy` (default) | builds + deploys the factory contracts |
| `join_with_builds` | builds the factory contracts in ContractManager (for ABI visibility), uses a pre-existing deployment |
| `join` | uses a pre-existing deployment — no ContractManager resources created |

## Settings

| Setting | Default | Usage |
|---------|---------|-------|
| `paladin_ref` | required | Paladin git ref (branch or commit SHA) to source contracts from |
| `paladin_repo` | `https://github.com/LFDT-Paladin/paladin` | Paladin GitHub repo URL — can be overriden to build from a fork |
| `factory_initializer_selector` | `0x8129fc1c` | selector for Pente factory `initialize()` |
| `environment_id` | required | environment holding the services and network |
| `contracts_service_id` | required | ContractManagerService for builds |
| `mode` | `deploy` | `deploy` builds + deploys the factory contracts; `join` / `join_with_builds` use a pre-existing deployment (see [Modes](#modes)) |
| `connector_service_id` | `null` | EVMConnector service that submits the deploys — **required in `deploy` mode** |
| `connector_api_name` | `evm` | EVM standard API name on the connector (`standard_api_name` output of middleware-evm-connector) |
| `signing_key_address` / `signing_key_uri` | `null` | deploy signer — **exactly one required in `deploy` mode** |
| `existing_factory_address` | `null` | factory (proxy) address — **required in `join` / `join_with_builds` mode** |
| `plugin_class` | `io.kaleido.paladin.pente.domain.PenteDomainFactory` | plugin entry-point class |
| `resource_prefix` | `""` | prefix for build names (multiple networks per CMS) |
| `build_path` | `Paladin` | ContractManager folder for the builds |

**Note: the signer becomes the factory owner and UUPS upgrade authority**

## Usage

```hcl
module "pente" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-pente?ref=main"

  paladin_ref          = "5baa0c8e5f8b7b55e5055de9cef2a83b1b361dae"
  environment_id       = kaleido_platform_environment.env.id
  contracts_service_id = var.contracts_service_id
  connector_service_id = var.connector_service_id
  signing_key_address  = kaleido_platform_kms_key.deployer.address
}

module "paladin_node_1" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-node?ref=main"

  # … network/stack/base-ledger settings …
  domains = merge(module.noto.domain, module.pente.domain)
}
```

Module calls that reference an existing factory set `mode = "join"` (or
`"join_with_builds"`) and `existing_factory_address` to the deploying call's
published `factory_address` output.

## Outputs

| Output | Description |
|--------|-------------|
| `factory_address` | Factory (proxy) address — publish for `join` / `join_with_builds` module calls |
| `domain` | Ready-to-merge `domains` fragment for `chaininfra-paladin-node` |
| `build_ids` | CMS build IDs keyed by contract |
