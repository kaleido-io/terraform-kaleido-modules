# chaininfra-paladin-pente

Registers the **pente** domain for a Paladin network: builds and deploys the pente
factory contracts (once per network, by the operator), and emits a `domain` config
fragment for [chaininfra-paladin-node](../chaininfra-paladin-node)'s `domains`
variable (every node).

## Modes

| | `mode = "deploy"` | `mode = "existing"` |
|---|---|---|
| `create_builds = true` (default) | builds + deploys — **operator** | builds only — **joiner with ABI visibility** |
| `create_builds = false` | invalid | config only, no resources — **lightweight joiner** |

## Settings

| Setting | Default | Usage |
|---------|---------|-------|
| `paladin_ref` | required | Paladin git ref (branch or commit SHA) to source contracts from |
| `paladin_repo` | `https://github.com/LFDT-Paladin/paladin` | Paladin GitHub repo URL — can be overriden to build from a fork |
| `environment_id` | required | environment holding the services and network |
| `contracts_service_id` | required | ContractManagerService for builds/deploys |
| `mode` | `deploy` | `deploy` deploys the factory; `existing` wraps an already-deployed one |
| `txnmanager_service_id` | `null` | TransactionManagerService — **required in `deploy` mode** |
| `signing_key_address` / `signing_key_uri` | `null` | deploy signer — **exactly one required in `deploy` mode** |
| `existing_factory_address` | `null` | factory (proxy) address — **required in `existing` mode** |
| `create_builds` | `true` | CMS builds for ABI visibility; must stay `true` in `deploy` mode |
| `plugin_class` | `io.kaleido.paladin.pente.domain.PenteDomainFactory` | plugin entry-point class |
| `resource_prefix` | `""` | prefix for build/deploy names (multiple networks per CMS) |
| `build_path` | `Paladin` | ContractManager folder for the builds |

**Note: the signer becomes the factory owner and UUPS upgrade authority**

## Usage

```hcl
module "pente" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-pente?ref=main"

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

Joiners set `mode = "existing"` and `existing_factory_address` to the operator's
published `factory_address` output.

## Outputs

| Output | Description |
|--------|-------------|
| `factory_address` | Factory (proxy) address — publish to joiners |
| `domain` | Ready-to-merge `domains` fragment for `chaininfra-paladin-node` |
| `build_ids` | CMS build IDs keyed by contract |
