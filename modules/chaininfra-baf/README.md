# chaininfra-baf

Deploys a Blockchain Application Firewall (BAF) stack which is a subtype of the `chain_infrastructure`
stack (`BAFStack`) with an EVM Gateway configured for fine-grained access control.
Applications route chain traffic through this gateway; while evaluating attached [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/)
policy to the application to decide which JSON-RPC calls that application may be allowed.

Pair with [`chaininfra-besu-network`](../chaininfra-besu-network), which outputs the
`network_id` this module requires. Besu nodes in the same environment provide the
underlying chain the BAF gateway fronts.

Unlike [`chaininfra-evm-gateway`](../chaininfra-evm-gateway), this module creates its
own stack and enables gateway features required for policy enforcement:

| Setting | Value |
|---------|-------|
| `decodeRawTransactions` | `true` — decode `eth_sendRawTransaction` payloads before policy evaluation |
| `fineGrainedPermissions` | `true` — evaluate per-request Rego policies on gateway traffic |

When `hostname` is set, the gateway publishes `jsonrpc`, `jsonrpcws`, and `graphql`
endpoints.

## Policies

Policies are [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) documents
attached to the BAF gateway via `kaleido_platform_service_access_policy`. Each entry in
the `policies` input scopes a policy to a single **application** — the Kaleido
application identity whose API keys authenticate against this gateway.

Provide policy text with **one** of:

- `file` — path to a `.rego` file (for example `file("${path.module}/resources/my-policy.rego")`)
- `rego` — inline Rego source

Every entry requires `application_id` (for example `ap:jrq4hmi72j` from an existing
`kaleido_platform_application`). Create the application separately, then reference its
ID here so only that caller is subject to the policy.

Gateway policies use the `gateway_permission` package. The platform evaluates `allow`
against each JSON-RPC request; denied calls are rejected before they reach the chain.
With `decodeRawTransactions` enabled, policies can inspect decoded transaction fields
(such as `input.params[0].from` on `eth_sendRawTransaction`).

See [`examples/chaininfra-besu/resources/sample-baf-policy`](../../examples/chaininfra-besu/resources/sample-baf-policy)
for a starter policy that allows only `eth_call` and `eth_sendRawTransaction`, and
restricts submitters to an allow-listed `from` address:

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

Attach multiple policies to grant different rules to different applications. Each
`policies` entry creates one `kaleido_platform_service_access_policy` on the BAF
gateway's `service_id`.

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
    {
      rego           = file("${path.module}/resources/other-policy.rego")
      application_id = "ap:existing-app-id"
    },
  ]
}
```

## Outputs

- `service_id`, `runtime_id`, `stack_id`
- `endpoints`, `hostnames`
