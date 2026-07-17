# chaininfra-canton-validator-network

Deploys a Canton validator network (`kaleido_platform_network`, type `CantonValidator`)
and the `chain_infrastructure` stack (`CantonStack`) that wraps it. By default the
network initializes in `automated` mode.

## Required settings

| Setting | Description |
|---------|-------------|
| `environment_id` | Kaleido environment to deploy the network and stack into |
| `network_type` | Validator network flavour: `Sandbox`, `Devnet`, `Testnet`, or `Mainnet` (see table below) |

| `network_type` | Behaviour |
|----------------|-----------|
| `Sandbox` | Local sandbox that mimics the Global Synchronizer (Canton coins enabled) |
| `Devnet`, `Testnet`, `Mainnet` | Global synchronizer membership; set `sponsor_super_validator` to choose the sponsoring super validator |

## Optional settings

| Setting | Default | Usage |
|---------|---------|-------|
| `network_name` | `null` | Display name of the `CantonValidator` network; defaults to `network_type` when unset |
| `stack_name` | `null` | Display name of the `CantonStack`; defaults to `network_type` when unset |
| `sponsor_super_validator` | `Digital-Asset-1` | Sponsoring super validator for global networks (`Digital-Asset-1`, `Digital-Asset-2`, `Global-Synchronizer-Foundation`, `Cumberland-1`, `Cumberland-2`); ignored for `Sandbox` |

## Usage

### Canton Sandbox network configuration

Create a network configuration for creating a Canton Sandbox network that emulates the Global network.

```hcl
module "validator_network" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/chaininfra-canton-validator-network?ref=main"

  environment_id = kaleido_platform_environment.env.id
  network_type   = "Sandbox"
}
```

### Canton Testnet configuration
Create a network configuration for the Canton Testnet
```

module "validator_network_testnet" {
  source = "../../modules/chaininfra-canton-validator-network"

  environment_id          = kaleido_platform_environment.env.id
  network_type            = "Testnet"
  sponsor_super_validator = "Digital-Asset-1"
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `network_id` | ID of the `CantonValidator` network |
| `stack_id` | ID of the `CantonStack` wrapping the network |
