resource "kaleido_platform_environment" "env" {
  name = var.environment_name
}

## Chain infrastructure: Besu network + chain-infrastructure stack

module "besu_network" {
  source         = "../../modules/chaininfra-besu-network"
  environment_id = kaleido_platform_environment.env.id
  network_name   = "besu"
  stack_name     = "besu"
}

## A signing validator node

module "besu_signer" {
  source         = "../../modules/chaininfra-besu-node"
  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.besu_network.stack_id
  network_id     = module.besu_network.network_id
  node_name      = "besu-signer-1"
  signer         = true
}

## A non-signing archive RPC peer (defaults: signer=false, FULL/archive, TRACE, BONSAI)

module "besu_peer" {
  source         = "../../modules/chaininfra-besu-node"
  environment_id = kaleido_platform_environment.env.id
  stack_id       = module.besu_network.stack_id
  network_id     = module.besu_network.network_id
  node_name      = "besu-peer-1"
  runtime_size   = "Medium"
}
