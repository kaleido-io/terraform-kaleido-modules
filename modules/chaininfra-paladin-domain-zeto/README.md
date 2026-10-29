# chaininfra-paladin-domain-zeto

Registers the **zeto** domain for a Paladin network: builds and deploys the Zeto
factory, the `Zeto_Anon` fungible token implementation and its Groth16 verifiers,
registers the implementation with the factory, and emits a `domain` config
fragment for [chaininfra-paladin-node](../chaininfra-paladin-node)'s `domains`
variable.

Deploys and the registration call are submitted through an EVM Connector's standard
API as idempotent workflow-engine transactions — each resource only ever submits one
unique transaction. Deployment records live in the connector's transactions API, not
in ContractManager (builds remain in CMS for ABI visibility / block-indexer decoding).

## Zeto release archives

The module takes the three archives of a Zeto release by URL. Each is an `http://` or
`https://` URL, or a local file as `file:///abs/path` or `file:relative/path`:

| Variable | Archive (Zeto v0.2.2 release asset) | Used for |
|----------|-------------------------------------|----------|
| `contracts_archive_url` | `zeto-contracts-v0.2.2.tar.gz` | `Zeto_Anon` and the Groth16 verifiers, read at plan time into `precompiled` ContractManager builds |
| `proving_keys_archive_url` | `zeto-test-proving-keys-v0.2.2.tar.gz` | `<circuit>.zkey` proving keys for the nodes, and `<circuit>-vkey.json` verification keys for the verifier check |
| `circuits_archive_url` | `zeto-wasm-v0.2.2.tar.gz` | `<circuit>_js/<circuit>.wasm` circuits for the nodes |

Archives can be `.zip`, `.tar.gz`, `.tgz` or `.gz` (a gzipped tar). The three must come
from the same release: Paladin v1.0.0 uses Zeto **v0.2.2**. The `-test-` proving keys
come from a test trusted setup, so use them only for development.

**Verifier check.** A verifier contract embeds its circuit's verification key, and rejects
proofs made with any other proving key. When `proving_keys_archive_url` is a `file:` URL,
the module checks each verifier against its `<circuit>-vkey.json` before deploying it, and
fails the plan on a mismatch. The check is skipped for remote URLs, so that the proving
keys archive (1.3 GB for v0.2.2) isn't downloaded on every plan.

**Node installation.** The proving keys and circuits are needed on every Paladin node, and
the module passes them on through its `node_zeto_artifacts` output. The platform can't
install them on nodes yet, so the nodes still use the test keys and circuits built into
the Paladin node image at `snark_prover_dir` (`/app/domains/zeto/zkp`), which match the
v0.2.2 release.

`ZetoFactory` (from `paladin_repo` @ `paladin_ref`) and its `ERC1967Proxy` (OpenZeppelin
v5.1.0) are not part of the Zeto release, and are built from GitHub.

Only `Zeto_Anon` is registered. The nullifier variants need Poseidon library linking, and
the lock/burn verifiers are left unset because `Zeto_Anon` doesn't support them.

## Modes

| `mode` | Behavior |
|--------|----------|
| `deploy` (default) | builds + deploys the factory, verifiers and token implementation, and registers `Zeto_Anon` |
| `join_with_builds` | builds the contracts in ContractManager (for ABI visibility), uses a pre-existing deployment |
| `join` | uses a pre-existing deployment — no ContractManager resources created |

## Settings

| Setting | Default | Usage |
|---------|---------|-------|
| `paladin_ref` | required | Paladin git ref (branch or commit SHA) to source `ZetoFactory` from |
| `paladin_repo` | `https://github.com/LFDT-Paladin/paladin` | Paladin GitHub repo URL — can be overriden to build from a fork |
| `contracts_archive_url` | required | Zeto contracts archive URL (`http(s)://` or `file:`) — see [Zeto release archives](#zeto-release-archives) |
| `proving_keys_archive_url` | required | Zeto proving keys archive URL — a `file:` URL also enables the verifier check |
| `circuits_archive_url` | required | Zeto circuits (wasm) archive URL |
| `factory_initializer_selector` | `0x8129fc1c` | selector for `ZetoFactory` `initialize()` |
| `snark_prover_dir` | `/app/domains/zeto/zkp` | circuits / proving keys directory on the nodes (default: built into the node image) |
| `environment_id` | required | environment holding the services and network |
| `contracts_service_id` | required | ContractManagerService for builds |
| `mode` | `deploy` | see [Modes](#modes) |
| `connector_service_id` | `null` | EVMConnector service that submits the deploys and registration — **required in `deploy` mode** |
| `connector_api_name` | `evm` | EVM standard API name on the connector (`standard_api_name` output of middleware-evm-connector) |
| `signing_key_address` / `signing_key_uri` | `null` | deploy signer — **exactly one required in `deploy` mode** |
| `factory_address` | `null` | factory (proxy) address — **required in `join` / `join_with_builds` mode** |
| `resource_prefix` | `""` | prefix for build names (multiple networks per CMS) |
| `build_path` | `Paladin` | ContractManager folder for the builds |

**Note: the signer becomes the factory owner and UUPS upgrade authority**

## Node wallets

Zeto keys are BabyJubJub keys that live outside the Key Manager for now. Each Paladin
node needs a `zeto_wallet_prefix` and a `zeto_wallet_seed` (BIP39 mnemonic) in its
`wallets` variable. The prefix is an unanchored regular expression, so anchor it
(e.g. `^zeto\\.`) and use identities such as `zeto.alice` for Zeto transactions.

**Why a separate wallet.** A Zeto transfer isn't signed. The node builds a zero-knowledge proof,
and the raw private key is an input to that proof. So the Paladin node must hold Zeto keys in
memory. The Key Manager can't provide them: it signs without handing out keys, and has no
BabyJubJub key type. The prefix sends Zeto identities to a wallet built into the node, which
derives their keys from the seed. Every other identity goes to the Key Manager.

The seed is the only copy of the node's Zeto keys. Back it up, because if it's lost those
coins can't be spent. Keep it secret, because anyone holding it can spend them. Terraform
stores it in its state.

**Alternatives.** The Key Manager could hold the keys and hand them to the node, which would
add central custody and audit with no changes to Paladin's Zeto code. Or the Key Manager could
build the proofs itself, keeping keys inside it, at the cost of hosting the circuits and the
1.3 GB of proving keys. Neither is available on the platform yet.

## Usage

```hcl
module "zeto" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-domain-zeto?ref=main"

  paladin_ref              = "5baa0c8e5f8b7b55e5055de9cef2a83b1b361dae"
  contracts_archive_url    = "https://github.com/LFDT-Paladin/zeto/releases/download/v0.2.2/zeto-contracts-v0.2.2.tar.gz"
  proving_keys_archive_url = "file:///path/to/zeto-test-proving-keys-v0.2.2.tar.gz"
  circuits_archive_url     = "https://github.com/LFDT-Paladin/zeto/releases/download/v0.2.2/zeto-wasm-v0.2.2.tar.gz"
  environment_id       = kaleido_platform_environment.env.id
  contracts_service_id = var.contracts_service_id
  connector_service_id = var.connector_service_id
  signing_key_address  = kaleido_platform_kms_key.deployer.address
}

module "paladin_node_1" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-paladin-node?ref=main"

  # … network/stack/base-ledger settings …
  wallets = {
    # …
    zeto_wallet_prefix = "^zeto\\."
    zeto_wallet_seed   = var.zeto_wallet_seed
  }
  domains = merge(module.noto.domain, module.zeto.domain)
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `factory_address` | Factory (proxy) address |
| `domain` | domain config used in `domains` fragment for `chaininfra-paladin-node` |
| `node_zeto_artifacts` | proving keys / circuits archive URLs and circuit names, for installing on the nodes |
| `build_ids` | CMS build IDs keyed by contract |
