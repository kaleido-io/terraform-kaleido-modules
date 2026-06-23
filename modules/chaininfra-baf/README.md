# chaininfra-baf

Deploys a Blockchain Application Firewall (BAF) stack — a `chain_infrastructure`
stack (`BAFStack`) with an EVM Gateway configured for fine-grained access control.
Applications route chain traffic through this gateway; attached Rego policies decide
which JSON-RPC calls each application may make.

The gateway enables `decodeRawTransactions` and `fineGrainedPermissions` for policy
enforcement. When `hostname` is set, the gateway publishes `jsonrpc`, `jsonrpcws`,
and `graphql` endpoints.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the BAF stack into |
| `stack_name` | Display name of the `BAFStack` and gateway |
| `network_id` | [`network_id`](../chaininfra-besu-network#outputs) from [`chaininfra-besu-network`](../chaininfra-besu-network) — `BesuNetwork` the gateway fronts |
| `policies` | List of Rego policies to attach (see [Policies](#policies)) |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `runtime_size` | `Small` | EVM Gateway runtime size |
| `hostname` | `null` | Custom hostname for the BAF gateway |

## Policies

Each entry in `policies` creates a `kaleido_platform_service_access_policy` scoped
to one Kaleido application. Provide policy text with **one** of `file` (path to a
`.rego` file) or `rego` (inline source). Every entry requires `application_id`.

See [`examples/chaininfra-besu/resources/sample-baf-policy`](../../examples/chaininfra-besu/resources/sample-baf-policy)
for a starter policy.

```rego
package gateway_permission

default allow := false

is_valid_method if {
  {"eth_call": true, "eth_sendRawTransaction": true}[input.method] == true
}

signer_address_allowed if input.method != "eth_sendRawTransaction"
signer_address_allowed if {
  {"0x12F62772C4652280d06E64CfBC9033d409559aD4": true}[input.params[0].from] == true
}

allow if {
  is_valid_method
  signer_address_allowed
}
```

## Usage

```hcl
module "besu_network" {
  source = "../../modules/chaininfra-besu-network"

  environment_id = kaleido_platform_environment.env.id
  network_name   = "besu"
  stack_name     = "besu"
}

module "baf" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-baf?ref=main"

  environment_id = kaleido_platform_environment.env.id
  network_id     = module.besu_network.network_id
  stack_name     = "besu-baf"
  hostname       = "besu-baf"

  policies = [
    {
      file           = "${path.module}/resources/sample-baf-policy"
      application_id = kaleido_platform_application.my_app.id
    },
  ]
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the BAF `EVMGateway` service |
| `runtime_id` | ID of the BAF `EVMGateway` runtime |
| `stack_id` | ID of the `BAFStack` |
| `endpoints` | Map of published service endpoints |
| `hostnames` | Map of custom hostnames bound to the service |
