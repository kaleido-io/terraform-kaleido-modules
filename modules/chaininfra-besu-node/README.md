# chaininfra-besu-node

Deploys a single Besu node (`BesuNode` runtime + service) into an existing
chain-infrastructure stack and Besu network. Pair with the
[`chaininfra-besu-network`](../chaininfra-besu-network) module, which outputs the
`stack_id` and `network_id` this module requires.

Service-config defaults codify Kaleido best practices for an archive RPC node:

| Setting | Default |
|---------|---------|
| `signer` | `false` |
| `log_level` | `INFO` |
| `sync_mode` | `FULL` (archive) |
| `apis_enabled` | `["TRACE"]` |
| `custom_besu_args` | `["--revert-reason-enabled"]` |
| `data_storage_format` | `BONSAI` |

Runtime placement (`runtime_size`, `zone`, `storage_type`, `storage_size`)
defaults to `null` so the platform's defaults apply unless overridden.

## Usage

```hcl
module "besu_signer" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-besu-node?ref=main"

  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.besu_network.stack_id
  network_id     = module.besu_network.network_id
  node_name      = "besu-signer-1"
  signer         = true
}

module "besu_peer" {
  source = "../../modules/chaininfra-besu-node"

  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.besu_network.stack_id
  network_id     = module.besu_network.network_id
  node_name      = "besu-peer-1"
  runtime_size   = "Medium"
}
```

## Outputs

- `service_id`, `runtime_id`, `node_name`
- `connectivity_json` — peer descriptor for building network connectors
- `endpoints`, `hostnames`
