# chaininfra-canton-synchronizer-network

Deploys a Canton synchronizer network (`kaleido_platform_network`, type
`CantonSynchronizer`) and optionally the `chain_infrastructure` stack (`CantonStack`)
that wraps it. When `external_sequencer_endpoint` is unset the network is `Local`;
when set it is `Remote` and points at an external sequencer.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the synchronizer network into |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `network_name` | `local-synchronizer` | Display name of the `CantonSynchronizer` network |
| `stack_enabled` | `true` | Create a `CantonStack` alongside the network; `stack_id` is `null` when `false` |
| `stack_name` | `null` | Display name of the `CantonStack`; defaults to `network_name` when unset |
| `external_sequencer_endpoint` | `null` | External sequencer endpoint for a `Remote` synchronizer network |

## Usage
Create a Synchronizer network to bootstrap the Private Synchronizer that the participant in that network can connect. 

```hcl
module "synchronizer_network" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-canton-synchronizer-network?ref=main"

  environment_id = kaleido_platform_environment.env.id
  network_name   = "local-synchronizer"
  stack_enabled  = true
}

module "synchronizer_network_remote" {
  source = "../../modules/chaininfra-canton-synchronizer-network"

  environment_id              = kaleido_platform_environment.env.id
  network_name                = "remote-synchronizer"
  stack_enabled               = false
  external_sequencer_endpoint = "sequencer.example.com:443"
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `network_id` | ID of the `CantonSynchronizer` network |
| `stack_id` | ID of the `CantonStack` wrapping the network; `null` when `stack_enabled` is `false` |
