# middleware-paladin-connector

Deploys a Paladin connector (`PaladinConnectorStack` + `PaladinConnector` runtime and
service). 

## Prerequisites

- Kaleido Enterprise Platform **26.9.0 or later**
- A **KeyManager** service in the target environment, passed as `key_manager_service_id`.
- A **WorkflowEngine** service in the target environment. The platform auto-binds it to
  the connector autoamtically, but we `depends_on` it so the
  connector is created after it.
- A **PaladinNode** service in the target environment, passed as `paladin_node_service_id`.

## Node binding

`paladin_node_service_id` is the [`service_id`](../chaininfra-paladin-node#outputs) output
of [`chaininfra-paladin-node`](../chaininfra-paladin-node). The node must be in the **same
environment** as the connector.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the connector into; a `WorkflowEngine` service must already exist there |
| `key_manager_service_id` | ID of the `KeyManager` service to bind to the connector |
| `paladin_node_service_id` | ID of the `PaladinNode` service to bind the connector to; must be in the same environment |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `stack_name` | `paladin-connector` | Name of the `PaladinConnectorStack` |
| `connector_name` | `paladin-connector` | Name of the runtime and service |
| `runtime_size` | `Small` | Runtime size: `ExtraSmall`, `Small`, `Medium`, `Large`, `ExtraLarge` |
| `runtime_zone` | `null` | Deployment zone; `null` uses the platform default |
| `ecosystem` | `{ name = "paladin", displayName = "Paladin" }` | Ecosystem metadata; the name must stay `paladin` to match the connector-manager definitions |
| `network` | `null` | Network display metadata (e.g. `{ name = "paladin-network" }`) |
| `monitoring` | `{}` | `paladin.monitoring` — receipt polling interval for the submission-style flows (default `5s`) |
| `transaction_events` | `{}` | `paladin.transactionEventsConfig` — receipt listener tuning for streams created from the `receiptEvents` factory |

## What gets deployed

| Kind | Name(s) | Notes |
|------|---------|-------|
| Config types | `paladin.monitoring`, `paladin.transactionEventsConfig` | Template ensure / version pin |
| Config profiles | `paladin.monitoring`, `paladin.transactionEventsConfig`, `receiptCorrelation` | The first two take their values from `monitoring` and `transaction_events`; `receiptCorrelation` is pinned to `{ pollTimeout = "1s", batchSize = 50, unfiltered = true }` |
| Connector flows | `submission`, `call`, `pgroupCreate`, `pgroupSubmission`, `pgroupCall` | `submission`, `pgroupCreate` and `pgroupSubmission` bind the `paladin.monitoring` profile (required by their receipt-monitoring stage); `call` and `pgroupCall` are synchronous and bind nothing |
| Stream factory | `receiptEvents` | Source for receipt streams; consumes `paladin.transactionEventsConfig` |
| Standard API | `paladin` | Binds the five flow types above |
| Standard stream | `receiptCorrelation` | Drives receipt confirmation for the submission flows; bound to the `receiptCorrelation` profile |

Operations exposed by the `paladin` standard API:

| Category | Operations | Flow type |
|----------|------------|-----------|
| `public` | `deploy`, `invoke` (async), `call` (sync) | `submission`, `call` |
| `private` | `deploy`, `invoke` (async), `call` (sync) | `submission`, `call` |
| `pgroup` | `create` (async) | `pgroupCreate` |
| `pgroup` | `deploy`, `invoke` (async), `call` (sync) | `pgroupSubmission`, `pgroupCall` |

## Usage

```hcl
module "paladin_connector" {
  source = "https://github.com/kaleido-io/terraform-kaleido-modules/modules/middleware-paladin-connector?ref=main"

  environment_id          = kaleido_platform_environment.env.id
  key_manager_service_id  = kaleido_platform_service.keymanager.id
  paladin_node_service_id = module.paladin_node.service_id
  network                 = { name = "paladin-network" }

  depends_on = [kaleido_platform_service.workflow_engine]
}
```

Or with the sample `*.tfvars` file:

```
terraform apply -var-file=modules/middleware-paladin-connector/examples/node-binding.tfvars
```

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the `PaladinConnector` service |
| `service_name` | Name of the `PaladinConnector` service |
| `stack_id` | ID of the `PaladinConnectorStack` |
| `runtime_id` | ID of the `PaladinConnector` runtime |
| `endpoints` | Published endpoints (the `rest` API at `/api/v1`) |
| `standard_api_name` | Name of the deployed `paladin` standard API |
| `standard_api_id` | ID of the deployed `paladin` standard API |
| `flow_ids` | Map of flow name to deployed flow ID (`submission`, `call`, `pgroupCreate`, `pgroupSubmission`, `pgroupCall`) |
| `flow_names` | Map of flow name to deployed flow name (same keys) |
| `stream_factory_id` | ID of the `receiptEvents` stream factory |
| `standard_stream_id` | ID of the `receiptCorrelation` standard stream |
| `config_profiles` | Map of config profile name to deployed config profile ID (`paladin.monitoring`, `paladin.transactionEventsConfig`, `receiptCorrelation`) |
