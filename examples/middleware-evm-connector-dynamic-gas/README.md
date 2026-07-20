# EVM Connector with dynamic gas pricing

This example deploys an EVM Connector against a public EVM network (Ethereum Sepolia) and
configures **dynamic gas pricing profile selection**: multiple named gas pricing profiles are
created and a JSONata expression on the connector's submission flow binding selects the right
profile at transaction submission time based on the caller's request.

## How it works

1. Three `evm.gasPricing` config profiles are deployed on the connector service:
   - `evm.gasPricing` — the default, used when no profile is specified
   - `evm.gasPricing_low` — conservative settings (lower percentile, larger history window, small buffer)
   - `evm.gasPricing_high` — aggressive settings (higher percentile, shorter history window, larger buffer)

2. A `kaleido_platform_connector_flow_config_binding` resource patches the submission flow's
   `gasPricing` config-profile slot with a `dynamicMapping`. At submission time the connector
   evaluates the JSONata expression against the transaction state to resolve the profile name.

3. Callers select a profile by passing `options.gasPricing.configProfileName` in the transaction
   request body (e.g. `"evm.gasPricing_high"`). Transactions that omit the option fall back to
   the default `evm.gasPricing` profile.

## Modules used

| Module | Role |
|--------|------|
| [`middleware-evm-connector`](../../modules/middleware-evm-connector) | Deploys the EVM Connector stack, named gas pricing profiles, and the dynamic binding on the submission flow |

## Additional resources

| Resource | Role |
|----------|------|
| `kaleido_platform_runtime` (`KeyManager`) | Runtime for the Key Manager service |
| `kaleido_platform_service` (`KeyManager`) | Key Manager service used to sign EVM transactions |

## Required settings

| Setting | Description |
|---------|-------------|
| `kaleido_platform_api` | Base URL of your Kaleido Platform API |
| `kaleido_platform_username` | Kaleido Platform API username |
| `kaleido_platform_password` | Kaleido Platform API password (sensitive) |
| `jsonrpc_url` | JSON-RPC endpoint URL of the EVM network |

## Optional settings

| Setting | Default | Description |
|---------|---------|-------------|
| `environment_name` | `evm-dynamic-gas` | Name of the environment to create |
| `key_manager_name` | `keys` | Name of the KeyManager runtime and service |
| `jsonrpc_auth` | `null` | Basic-auth credentials for the JSON-RPC endpoint |

## Usage

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values.

### OpenTofu

```bash
tofu init
tofu plan
tofu apply
```

### Terraform

```bash
terraform init
terraform plan
terraform apply
```

After apply the `gas_pricing_profile_names` output lists the deployed named profiles.

To use dynamic profile selection, pass `options.gasPricing.configProfileName` in the
transaction submission request:

```json
{
  "idempotencyKey": "my-tx-1",
  "input": { ... },
  "options": {
    "gasPricing": {
      "configProfileName": "evm.gasPricing_high"
    }
  }
}
```

### Destroy

```bash
tofu destroy
```

or

```bash
terraform destroy
```
