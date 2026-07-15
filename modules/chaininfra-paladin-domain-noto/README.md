# chaininfra-paladin-noto

Registers the **noto** domain for a Paladin network: builds and deploys the noto
factory contracts, and emits a `domain` config
fragment for [chaininfra-paladin-node](../chaininfra-paladin-node)'s `domains`
variable.

Also creates CMS builds of common Paladin contracts, e.g. `Atom` for atomic settlement. This allows the Kaleido
Block Indexer to decode these function signatures.

## Modes

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
| `factory_initializer_selector` | `0xc4d66de8` | selector for Noto factory `initialize(address)` — the module appends the deployed Noto implementation address |
| `environment_id` | required | environment holding the services and network |
| `contracts_service_id` | required | ContractManagerService for builds/deploys |
| `mode` | `deploy` | `deploy` builds + deploys the factory contracts; `join` / `join_with_builds` use a pre-existing deployment (see [Modes](#modes)) |
| `txnmanager_service_id` | `null` | TransactionManagerService — **required in `deploy` mode** |
| `signing_key_address` / `signing_key_uri` | `null` | deploy signer — **exactly one required in `deploy` mode** |
| `factory_address` | `null` | factory (proxy) address — **required in `join` / `join_with_builds` mode** |
| `resource_prefix` | `""` | prefix for build/deploy names (multiple networks per CMS) |
| `build_path` | `Paladin` | ContractManager folder for the builds |

**Note: the signer becomes the factory owner and UUPS upgrade authority**

## Usage

```hcl
module "noto" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-noto?ref=main"

  paladin_ref           = "5baa0c8e5f8b7b55e5055de9cef2a83b1b361dae"
  environment_id        = kaleido_platform_environment.env.id
  contracts_service_id  = var.contracts_service_id
  txnmanager_service_id = var.txnmanager_service_id
  signing_key_address   = kaleido_platform_kms_key.deployer.address
}

module "paladin_node_1" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-node?ref=main"

  # … network/stack/base-ledger settings …
  domains = merge(module.noto.domain, module.pente.domain)
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `factory_address` | Factory (proxy) address |
| `domain` | domain config  used in `domains` fragment for `chaininfra-paladin-node` |
| `build_ids` | CMS build IDs keyed by contract |
