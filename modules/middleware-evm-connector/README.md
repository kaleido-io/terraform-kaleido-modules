# middleware-evm-connector

Deploys an EVM connector service (`EVMConnectorStack` + runtime + service) with
config types, config profiles, connector flows, stream factories, and the standard
API it ships with. Per-ecosystem behaviour is controlled by the typed config-profile
variables.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the connector into |
| `key_manager_service_id` | ID of the `KeyManager` service used to sign EVM transactions |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `stack_name` | `evm` | Name of the `EVMConnectorStack` |
| `connector_name` | `evm-connector` | Display name of the runtime and service |
| `runtime_size` | `Small` | `EVMConnector` runtime size |
| `runtime_zone` | `null` | Deployment zone; `null` uses the platform default |
| `database_name` | `null` | External database name; required only on instances with externally-provisioned databases |
| `deploy_utilities_api` | `false` | Also deploy the EVM `utilities` standard API (synchronous operations such as looking up any transaction by hash) |
| `evm_gateway_service_id` | `null` | [`service_id`](../chaininfra-evm-gateway#outputs) from [`chaininfra-evm-gateway`](../chaininfra-evm-gateway) for Kaleido-managed Besu networks |
| `jsonrpc_url` | `null` | External JSON-RPC URL for public networks |
| `jsonrpc_auth` | `null` | Basic-auth credentials for the JSON-RPC endpoint (sensitive) |
| `ecosystem` | `null` | Ecosystem metadata (e.g. `{ name = "ethereum", displayName = "Ethereum" }`) |
| `network` | `null` | Network metadata (e.g. `{ name = "ethereum-mainnet", chainId = "1" }`) |
| `flow_versions` | `{}` | Template version per connector flow: a version to pin, `"latest"` to track, or omit to hold (see [Connector flow versions](#connector-flow-versions)) |
| `track_chain_defaults` | `false` | Follow the platform catalog's chain defaults as they change, rather than holding them from the first deploy (see [Chain defaults](#chain-defaults)) |
| `confirmations` | `null` | `evm.confirmations` — confirmation count and resubmission policy |
| `gas_estimation` | `null` | `evm.gasEstimation` — gas estimate scale factor |
| `gas_pricing` | `null` | `evm.gasPricing` — fee format, source, auto-increment, and caps |
| `nonce_assignment` | `null` | `evm.nonceAssignment` |
| `prioritization` | `null` | `evm.prioritization` — nonce assignment order: `fifo` or `tiered`. Omitted, no profile is created or bound and nonces are assigned in arrival order |
| `submission` | `null` | `evm.submission` — error-type matchers for submission retries |
| `transaction_serialization` | `null` | `evm.transactionSerialization` — `format`: `auto` or `original` |
| `block_events` | `null` | `evm.blockEventsConfig` — latest-block poller debounce timings |
| `transaction_events` | `null` | `evm.transactionEventsConfig` — block-walking event stream tuning |
| `contract_event_listener` | `null` | `evm.contractEventListener` — contract address + event ABI listener |

## Chain defaults

Each config profile variable (`confirmations`, `gas_pricing`, …) is the value of the connector's
default profile for that config type. A variable left `null` takes the **chain's default** from the
platform catalog, for the `ecosystem` and `network` — the same values the console applies when it
configures a connector, for example 12 confirmations with resubmission on for Ethereum mainnet. Where
the catalog has no value for a type, or no `ecosystem` is set, the connector's own defaults apply.

A value you set is **deep merged** into the chain's default, so only the settings you give change:
`confirmations = { count = 20 }` on Ethereum mainnet keeps the catalog's resubmission settings.
A setting you give wins, including `false` and `0`, and a list replaces the chain's list whole. A 
setting you leave out, or set to `null`, keeps the chain's value, so a chain setting can be changed 
but not removed: to turn resubmission off, set
`resubmission = { enabled = false }`.

The chain defaults are read when the connector is first deployed and then **held**, so a later change
to the catalog never changes a deployed connector's profiles on its own. Changing `ecosystem` or
`network` takes a fresh copy, and a config type the catalog gains a default for is picked up when it
first appears. When the catalog has since changed in a way that would change a deployed profile, the
plan shows a warning from the `chain_defaults_current` check. To take the current defaults, either:

- set `track_chain_defaults = true` to follow the catalog from then on, with every change shown in
  the plan, or
- take them once, with `terraform apply -replace='module.<name>.terraform_data.chain_default["evm.confirmations"]'`.


## Connector flow versions

Each connector flow (`submission`, `query`) runs a version of the connector's flow template. New
platform releases add template versions; `flow_versions` decides when a flow moves to one. There are
three strategies, set per flow.

**Held (the default).** Leave the flow out. It is deployed at the latest version and then stays there,
so a platform release never upgrades it on its own. When a newer version is available the plan shows
a warning from the `flow_versions_current` check, naming the version to move to.

```hcl
module "evm" {
  # ...
  # flow_versions not set: both flows held at the version they were first deployed at
}
```

**Pinned.** Set a version. The flow is deployed or upgraded to exactly that version, and moves only
when you change it. A pinned flow is never warned about.

```hcl
  flow_versions = {
    submission = "2026.09.0"
  }
```

**Latest.** Set `"latest"`. The flow is upgraded whenever the connector service stores a newer
version, and each upgrade appears in the plan before it is applied.

```hcl
  flow_versions = {
    query = "latest"
  }
```

Strategies can be mixed, for example a pinned `submission` and a tracking `query`. The
`flow_versions` output shows the version each flow is deployed at, and `latest_flow_versions` the
newest version the connector stores.

### Changing strategy

| From | To | What you write | What happens |
|------|----|----------------|--------------|
| Held or pinned | A newer pin | `submission = "2026.10.0"` | The flow is upgraded to that version |
| Held or pinned | Latest | `submission = "latest"` | The flow is upgraded to the latest version now, and to each newer one after |
| Pinned or latest | Held | Remove the flow from `flow_versions` | Nothing changes: the flow stays at its deployed version, and the check warns when a newer one is available |
| Latest | Pinned | `submission = "<version it is at>"` | Nothing changes: the flow stops following new versions |
| Any | An older version | `submission = "2026.07.0"` | Refused at plan time: connector flows only move forward |

To upgrade a pinned flow, change its version, or set it to `"latest"`, and run `terraform plan`. The
plan shows the flow's `version` changing, which is the upgrade. Applying it upgrades the flow in place:
it keeps its ID and its config profile bindings. Pinning to a version the connector does not store,
or no longer supports, fails at apply with the connector's error; `latest_flow_versions` shows what is
available.

`prioritization` needs `submission` at 2026.09.0 or later: pinning it earlier while `prioritization`
is set fails at plan time.

The `evm` and `utilities` standard APIs, and the config types, are deployed at the connector's latest
version and are not upgraded by this module.

## Usage

```hcl
module "evm" {
  source = "https://github.com/kaleido-io/terraform-kaleido-modules/modules/middleware-evm-connector?ref=main"

  environment_id         = kaleido_platform_environment.env.id
  key_manager_service_id = kaleido_platform_service.keymanager.id

  ecosystem = { name = "besu", displayName = "Besu" }
  network   = { name = "besu-private", chainId = "3333" }

  confirmations = { count = 0 }
}
```

## Ecosystem presets

Drop-in `*.tfvars` files under `examples/`:

| File | Notes |
|------|-------|
| `besu.tfvars` | Private Besu, count=0, fixed zero-fee gas |
| `ethereum-mainnet.tfvars` | 12 confirmations, resubmission on |
| `ethereum-sepolia.tfvars` | 6 confirmations, resubmission on |
| `base-mainnet.tfvars` | 20 confirmations |
| `base-sepolia.tfvars` | 6 confirmations |
| `polygon-mainnet.tfvars` | 50 confirmations (reorg risk) |
| `polygon-amoy.tfvars` | 50 confirmations (reorg risk) |
| `arbitrum-sepolia.tfvars` | 6 confirmations |

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `EVMConnector` service |
| `stack_id` | ID of the `EVMConnectorStack` |
| `runtime_id` | ID of the `EVMConnector` runtime |
| `submission_flow_name` | Name of the deployed submission connector flow |
| `submission_flow_id` | ID of the deployed submission connector flow |
| `query_flow_name` | Name of the deployed query connector flow |
| `query_flow_id` | ID of the deployed query connector flow |
| `flow_ids` | Map of connector flow name to deployed flow ID (`submission`, `query`) |
| `flow_versions` | Map of connector flow name to the template version it is deployed at |
| `latest_flow_versions` | Map of connector flow name to the newest template version the connector stores |
| `standard_api_name` | Name of the deployed EVM standard API |
| `standard_api_id` | ID of the deployed EVM standard API |
| `utilities_api_id` | ID of the deployed EVM `utilities` standard API; `null` unless `deploy_utilities_api` is set |
| `stream_factories` | Map of deployed stream factory IDs (`block_events`, `transaction_events`) |
| `config_profiles` | Map of config-type name to deployed config profile ID |
| `config_profile_values` | Map of config-type name to its deployed profile's JSON value |
| `chain_defaults` | Map of config-type name to the catalog's default value (JSON) in use: held, or current when `track_chain_defaults` is set |

The flow IDs exist because workflow **subflow bindings take an ID, not a name**
(`subflowBindings: { <subflow>: { subflowId: "flw:..." } }`). Without them a
caller cannot bind its own `kaleido_platform_wfe_workflow` to the connector's
flows, since Terraform forbids referencing a module's internal resources.
