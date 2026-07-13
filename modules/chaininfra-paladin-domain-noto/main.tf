locals {
  deploy        = var.mode == "deploy"
  create_builds = var.mode != "join"

  # Either the signing_key_uri or signing_key_address of the intended signer
  # URI and address are interchangeable
  signing_identity = local.deploy ? coalesce(var.signing_key_uri, var.signing_key_address) : null

  paladin_base_url = "${trimsuffix(var.paladin_repo, "/")}/blob/${var.paladin_ref}"

  sources = {
    noto = {
      contract_url  = "${local.paladin_base_url}/solidity/contracts/domains/noto/Noto.sol"
      contract_name = "Noto"
    }
    noto_factory = {
      contract_url  = "${local.paladin_base_url}/solidity/contracts/domains/noto/NotoFactory.sol"
      contract_name = "NotoFactory"
    }
    noto_factory_proxy = {
      contract_url  = "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.1.0/contracts/proxy/ERC1967/ERC1967Proxy.sol"
      contract_name = "ERC1967Proxy"
    }
    atom = {
      contract_url  = "${local.paladin_base_url}/solidity/contracts/shared/Atom.sol"
      contract_name = "Atom"
    }
    atom_factory = {
      contract_url  = "${local.paladin_base_url}/solidity/contracts/shared/AtomFactory.sol"
      contract_name = "AtomFactory"
    }
    identity_registry = {
      contract_url  = "${local.paladin_base_url}/solidity/contracts/registry/IdentityRegistry.sol"
      contract_name = "IdentityRegistry"
    }
  }
}

# ContractManager builds
resource "kaleido_platform_cms_build" "noto" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}noto"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.noto.contract_url
    contract_name = local.sources.noto.contract_name
  }
}

resource "kaleido_platform_cms_build" "noto_factory" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}noto_factory"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.noto_factory.contract_url
    contract_name = local.sources.noto_factory.contract_name
  }

  depends_on = [kaleido_platform_cms_build.noto]
}

resource "kaleido_platform_cms_build" "noto_factory_proxy" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}noto_factory_proxy"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.noto_factory_proxy.contract_url
    contract_name = local.sources.noto_factory_proxy.contract_name
  }

  depends_on = [kaleido_platform_cms_build.noto_factory]
}

resource "kaleido_platform_cms_build" "atom" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}atom"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.atom.contract_url
    contract_name = local.sources.atom.contract_name
  }

  depends_on = [kaleido_platform_cms_build.noto_factory_proxy]
}

resource "kaleido_platform_cms_build" "atom_factory" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}atom_factory"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.atom_factory.contract_url
    contract_name = local.sources.atom_factory.contract_name
  }

  depends_on = [kaleido_platform_cms_build.atom]
}

resource "kaleido_platform_cms_build" "identity_registry" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}identity_registry"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.identity_registry.contract_url
    contract_name = local.sources.identity_registry.contract_name
  }

  depends_on = [kaleido_platform_cms_build.atom_factory]
}

moved {
  from = kaleido_platform_cms_build.this["noto"]
  to   = kaleido_platform_cms_build.noto[0]
}

moved {
  from = kaleido_platform_cms_build.this["noto_factory"]
  to   = kaleido_platform_cms_build.noto_factory[0]
}

# ContractManager deploys
resource "kaleido_platform_cms_action_deploy" "noto_impl" {
  count = local.deploy ? 1 : 0

  environment         = var.environment_id
  service             = var.contracts_service_id
  build               = kaleido_platform_cms_build.noto[0].id
  name                = "${var.resource_prefix}deploy_noto"
  transaction_manager = var.txnmanager_service_id
  signing_key         = local.signing_identity
}

resource "kaleido_platform_cms_action_deploy" "factory_impl" {
  count = local.deploy ? 1 : 0

  environment         = var.environment_id
  service             = var.contracts_service_id
  build               = kaleido_platform_cms_build.noto_factory[0].id
  name                = "${var.resource_prefix}deploy_noto_factory"
  transaction_manager = var.txnmanager_service_id
  signing_key         = local.signing_identity
}

resource "kaleido_platform_cms_action_deploy" "factory_proxy" {
  count = local.deploy ? 1 : 0

  environment         = var.environment_id
  service             = var.contracts_service_id
  build               = kaleido_platform_cms_build.noto_factory_proxy[0].id
  name                = "${var.resource_prefix}deploy_noto_factory_proxy"
  transaction_manager = var.txnmanager_service_id
  signing_key         = local.signing_identity

  # ERC1967Proxy constructor args: (implementation, initializer calldata).
  # The calldata is the initializer selector (default 0xc4d66de8 =
  # initialize(address)) followed by the deployed Noto implementation address
  # ABI-encoded (32-byte left-padded), delegatecalled by the proxy at deploy
  # time to initialize NotoFactory with the Noto implementation it clones for
  # new tokens.
  params_json = jsonencode([
    kaleido_platform_cms_action_deploy.factory_impl[0].contract_address,
    "${var.factory_initializer_selector}000000000000000000000000${replace(lower(kaleido_platform_cms_action_deploy.noto_impl[0].contract_address), "0x", "")}"
  ])
}

locals {
  factory_address = !local.deploy ? var.factory_address : try(
    kaleido_platform_cms_action_deploy.factory_proxy[0].contract_address, null
  )
}
