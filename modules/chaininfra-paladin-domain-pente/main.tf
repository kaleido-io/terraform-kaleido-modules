locals {
  deploy        = var.mode == "deploy"
  create_builds = var.mode != "join"

  # Either the signing_key_uri or signing_key_address of the intended signer
  # URI and address are interchangeable
  signing_identity = local.deploy ? coalesce(var.signing_key_uri, var.signing_key_address) : null

  paladin_base_url = "${trimsuffix(var.paladin_repo, "/")}/blob/${var.paladin_ref}"

  sources = {
    pente = {
      contract_url  = "${local.paladin_base_url}/solidity/contracts/domains/pente/PentePrivacyGroup.sol"
      contract_name = "PentePrivacyGroup"
    }
    pente_factory = {
      contract_url  = "${local.paladin_base_url}/solidity/contracts/domains/pente/PenteFactory.sol"
      contract_name = "PenteFactory"
    }
    pente_factory_proxy = {
      contract_url  = "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.1.0/contracts/proxy/ERC1967/ERC1967Proxy.sol"
      contract_name = "ERC1967Proxy"
    }
  }
}

# ContractManager builds
resource "kaleido_platform_cms_build" "pente" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}pente"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.pente.contract_url
    contract_name = local.sources.pente.contract_name
  }
}

resource "kaleido_platform_cms_build" "pente_factory" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}pente_factory"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.pente_factory.contract_url
    contract_name = local.sources.pente_factory.contract_name
  }

  depends_on = [kaleido_platform_cms_build.pente]
}

resource "kaleido_platform_cms_build" "pente_factory_proxy" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}pente_factory_proxy"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.pente_factory_proxy.contract_url
    contract_name = local.sources.pente_factory_proxy.contract_name
  }

  depends_on = [kaleido_platform_cms_build.pente_factory]
}

moved {
  from = kaleido_platform_cms_build.this["pente"]
  to   = kaleido_platform_cms_build.pente[0]
}

moved {
  from = kaleido_platform_cms_build.this["pente_factory"]
  to   = kaleido_platform_cms_build.pente_factory[0]
}

moved {
  from = kaleido_platform_cms_build.this["pente_factory_proxy"]
  to   = kaleido_platform_cms_build.pente_factory_proxy[0]
}

# ContractManager deploys
resource "kaleido_platform_cms_action_deploy" "factory_impl" {
  count = local.deploy ? 1 : 0

  environment         = var.environment_id
  service             = var.contracts_service_id
  build               = kaleido_platform_cms_build.pente_factory[0].id
  name                = "${var.resource_prefix}deploy_pente_factory"
  transaction_manager = var.txnmanager_service_id
  signing_key         = local.signing_identity
}

resource "kaleido_platform_cms_action_deploy" "factory_proxy" {
  count = local.deploy ? 1 : 0

  environment         = var.environment_id
  service             = var.contracts_service_id
  build               = kaleido_platform_cms_build.pente_factory_proxy[0].id
  name                = "${var.resource_prefix}deploy_pente_factory_proxy"
  transaction_manager = var.txnmanager_service_id
  signing_key         = local.signing_identity

  # ERC1967Proxy constructor args: (implementation, initializer calldata).
  # PenteFactory's initializer takes no arguments, so the calldata is just the
  # selector (default 0x8129fc1c = initialize()), delegatecalled by the proxy
  # at deploy time.
  params_json = jsonencode([
    kaleido_platform_cms_action_deploy.factory_impl[0].contract_address,
    var.factory_initializer_selector
  ])
}

locals {
  factory_address = !local.deploy ? var.existing_factory_address : try(
    kaleido_platform_cms_action_deploy.factory_proxy[0].contract_address, null
  )
}
