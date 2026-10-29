locals {
  deploy        = var.mode == "deploy"
  create_builds = var.mode != "join"

  # Either the signing_key_uri or signing_key_address of the intended signer
  # URI and address are interchangeable
  signing_identity = local.deploy ? coalesce(var.signing_key_uri, var.signing_key_address) : null

  paladin_base_url = "${trimsuffix(var.paladin_repo, "/")}/blob/${var.paladin_ref}"

  sources = {
    zeto_factory = {
      contract_url  = "${local.paladin_base_url}/solidity/contracts/domains/zeto/ZetoFactory.sol"
      contract_name = "ZetoFactory"
    }
    zeto_factory_proxy = {
      contract_url  = "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.1.0/contracts/proxy/ERC1967/ERC1967Proxy.sol"
      contract_name = "ERC1967Proxy"
    }
  }

  # Groth16 verifier contract for each circuit Zeto_Anon proves with. The verifiers embed
  # the circuit's verification key, so they must come from the same trusted setup as the
  # proving keys the nodes use.
  verifier_contracts = {
    anon           = "Groth16Verifier_Anon"
    anon_batch     = "Groth16Verifier_AnonBatch"
    deposit        = "Groth16Verifier_Deposit"
    withdraw       = "Groth16Verifier_Withdraw"
    withdraw_batch = "Groth16Verifier_WithdrawBatch"
  }

  zero_address = "0x0000000000000000000000000000000000000000"
}

# Compiled Zeto_Anon token and verifier contracts, read from the Zeto contracts archive
data "kaleido_platform_contract_archive" "zeto" {
  count = local.create_builds ? 1 : 0

  url       = var.contracts_archive_url
  contracts = concat(["Zeto_Anon"], values(local.verifier_contracts))
}

# Verification keys from a local proving keys archive, used to check the verifier contracts
# match the proving keys before deploying them. Skipped for remote archives, to avoid
# downloading the full proving keys archive on every plan.
data "kaleido_platform_contract_archive" "verification_keys" {
  count = local.deploy && startswith(var.proving_keys_archive_url, "file:") ? 1 : 0

  url       = var.proving_keys_archive_url
  contracts = []
  files     = [for circuit in keys(local.verifier_contracts) : "${circuit}-vkey.json"]
}

locals {
  # ABIs are normalized with jsonencode(jsondecode()) in the builds below, so that only a
  # change to the ABI itself, not its formatting in the archive, replaces a build
  artifacts = try(data.kaleido_platform_contract_archive.zeto[0].artifacts, {})

  # A Groth16 verifier embeds each verification key constant as a 32-byte word. Coordinates
  # of 0 and 1 (the projective z coordinate) are skipped as they match any bytecode.
  verifier_mismatches = {
    for circuit, contract in local.verifier_contracts : contract => [
      for n in flatten([for k, v in jsondecode(data.kaleido_platform_contract_archive.verification_keys[0].file_contents["${circuit}-vkey.json"]) : v if contains(["vk_alpha_1", "vk_beta_2", "vk_gamma_2", "vk_delta_2", "IC"], k)]) : n
      if !contains(["0", "1"], n) && !strcontains(lower(local.artifacts[contract].bytecode), format("%064x", tonumber(n)))
    ] if length(data.kaleido_platform_contract_archive.verification_keys) > 0
  }
}

# ContractManager builds
resource "kaleido_platform_cms_build" "zeto_factory" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}zeto_factory"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.zeto_factory.contract_url
    contract_name = local.sources.zeto_factory.contract_name
  }
}

resource "kaleido_platform_cms_build" "zeto_factory_proxy" {
  count = local.create_builds ? 1 : 0

  environment  = var.environment_id
  service      = var.contracts_service_id
  type         = "github"
  name         = "${var.resource_prefix}zeto_factory_proxy"
  path         = var.build_path
  solc_version = "v0.8.36+commit.8a079791"
  evm_version  = "shanghai"
  optimizer    = var.contract_optimizer

  github = {
    contract_url  = local.sources.zeto_factory_proxy.contract_url
    contract_name = local.sources.zeto_factory_proxy.contract_name
  }

  depends_on = [kaleido_platform_cms_build.zeto_factory]
}

resource "kaleido_platform_cms_build" "zeto_anon" {
  count = local.create_builds ? 1 : 0

  environment = var.environment_id
  service     = var.contracts_service_id
  type        = "precompiled"
  name        = "${var.resource_prefix}zeto_anon"
  path        = var.build_path

  precompiled = {
    abi      = jsonencode(jsondecode(local.artifacts["Zeto_Anon"].abi))
    bytecode = local.artifacts["Zeto_Anon"].bytecode
  }

  depends_on = [kaleido_platform_cms_build.zeto_factory_proxy]
}

resource "kaleido_platform_cms_build" "verifier_anon" {
  count = local.create_builds ? 1 : 0

  environment = var.environment_id
  service     = var.contracts_service_id
  type        = "precompiled"
  name        = "${var.resource_prefix}zeto_verifier_anon"
  path        = var.build_path

  precompiled = {
    abi      = jsonencode(jsondecode(local.artifacts[local.verifier_contracts.anon].abi))
    bytecode = local.artifacts[local.verifier_contracts.anon].bytecode
  }

  depends_on = [kaleido_platform_cms_build.zeto_anon]
}

resource "kaleido_platform_cms_build" "verifier_anon_batch" {
  count = local.create_builds ? 1 : 0

  environment = var.environment_id
  service     = var.contracts_service_id
  type        = "precompiled"
  name        = "${var.resource_prefix}zeto_verifier_anon_batch"
  path        = var.build_path

  precompiled = {
    abi      = jsonencode(jsondecode(local.artifacts[local.verifier_contracts.anon_batch].abi))
    bytecode = local.artifacts[local.verifier_contracts.anon_batch].bytecode
  }

  depends_on = [kaleido_platform_cms_build.verifier_anon]
}

resource "kaleido_platform_cms_build" "verifier_deposit" {
  count = local.create_builds ? 1 : 0

  environment = var.environment_id
  service     = var.contracts_service_id
  type        = "precompiled"
  name        = "${var.resource_prefix}zeto_verifier_deposit"
  path        = var.build_path

  precompiled = {
    abi      = jsonencode(jsondecode(local.artifacts[local.verifier_contracts.deposit].abi))
    bytecode = local.artifacts[local.verifier_contracts.deposit].bytecode
  }

  depends_on = [kaleido_platform_cms_build.verifier_anon_batch]
}

resource "kaleido_platform_cms_build" "verifier_withdraw" {
  count = local.create_builds ? 1 : 0

  environment = var.environment_id
  service     = var.contracts_service_id
  type        = "precompiled"
  name        = "${var.resource_prefix}zeto_verifier_withdraw"
  path        = var.build_path

  precompiled = {
    abi      = jsonencode(jsondecode(local.artifacts[local.verifier_contracts.withdraw].abi))
    bytecode = local.artifacts[local.verifier_contracts.withdraw].bytecode
  }

  depends_on = [kaleido_platform_cms_build.verifier_deposit]
}

resource "kaleido_platform_cms_build" "verifier_withdraw_batch" {
  count = local.create_builds ? 1 : 0

  environment = var.environment_id
  service     = var.contracts_service_id
  type        = "precompiled"
  name        = "${var.resource_prefix}zeto_verifier_withdraw_batch"
  path        = var.build_path

  precompiled = {
    abi      = jsonencode(jsondecode(local.artifacts[local.verifier_contracts.withdraw_batch].abi))
    bytecode = local.artifacts[local.verifier_contracts.withdraw_batch].bytecode
  }

  depends_on = [kaleido_platform_cms_build.verifier_withdraw]
}

# EVM connector deploys (idempotent - identity is a key derived from the inputs)
resource "kaleido_platform_evm_connector_contract_deploy" "verifier_anon" {
  count = local.deploy ? 1 : 0

  environment = var.environment_id
  service     = var.connector_service_id
  api         = var.connector_api_name
  key         = local.signing_identity
  abi         = kaleido_platform_cms_build.verifier_anon[0].abi
  bytecode    = kaleido_platform_cms_build.verifier_anon[0].bytecode

  lifecycle {
    precondition {
      condition     = length(lookup(local.verifier_mismatches, local.verifier_contracts.anon, [])) == 0
      error_message = "${local.verifier_contracts.anon} in the contracts archive does not match anon-vkey.json in the proving keys archive, so it would reject the nodes' proofs. Use contracts and proving keys from the same Zeto release or trusted setup."
    }
  }
}

resource "kaleido_platform_evm_connector_contract_deploy" "verifier_anon_batch" {
  count = local.deploy ? 1 : 0

  environment = var.environment_id
  service     = var.connector_service_id
  api         = var.connector_api_name
  key         = local.signing_identity
  abi         = kaleido_platform_cms_build.verifier_anon_batch[0].abi
  bytecode    = kaleido_platform_cms_build.verifier_anon_batch[0].bytecode

  lifecycle {
    precondition {
      condition     = length(lookup(local.verifier_mismatches, local.verifier_contracts.anon_batch, [])) == 0
      error_message = "${local.verifier_contracts.anon_batch} in the contracts archive does not match anon_batch-vkey.json in the proving keys archive, so it would reject the nodes' proofs. Use contracts and proving keys from the same Zeto release or trusted setup."
    }
  }
}

resource "kaleido_platform_evm_connector_contract_deploy" "verifier_deposit" {
  count = local.deploy ? 1 : 0

  environment = var.environment_id
  service     = var.connector_service_id
  api         = var.connector_api_name
  key         = local.signing_identity
  abi         = kaleido_platform_cms_build.verifier_deposit[0].abi
  bytecode    = kaleido_platform_cms_build.verifier_deposit[0].bytecode

  lifecycle {
    precondition {
      condition     = length(lookup(local.verifier_mismatches, local.verifier_contracts.deposit, [])) == 0
      error_message = "${local.verifier_contracts.deposit} in the contracts archive does not match deposit-vkey.json in the proving keys archive, so it would reject the nodes' proofs. Use contracts and proving keys from the same Zeto release or trusted setup."
    }
  }
}

resource "kaleido_platform_evm_connector_contract_deploy" "verifier_withdraw" {
  count = local.deploy ? 1 : 0

  environment = var.environment_id
  service     = var.connector_service_id
  api         = var.connector_api_name
  key         = local.signing_identity
  abi         = kaleido_platform_cms_build.verifier_withdraw[0].abi
  bytecode    = kaleido_platform_cms_build.verifier_withdraw[0].bytecode

  lifecycle {
    precondition {
      condition     = length(lookup(local.verifier_mismatches, local.verifier_contracts.withdraw, [])) == 0
      error_message = "${local.verifier_contracts.withdraw} in the contracts archive does not match withdraw-vkey.json in the proving keys archive, so it would reject the nodes' proofs. Use contracts and proving keys from the same Zeto release or trusted setup."
    }
  }
}

resource "kaleido_platform_evm_connector_contract_deploy" "verifier_withdraw_batch" {
  count = local.deploy ? 1 : 0

  environment = var.environment_id
  service     = var.connector_service_id
  api         = var.connector_api_name
  key         = local.signing_identity
  abi         = kaleido_platform_cms_build.verifier_withdraw_batch[0].abi
  bytecode    = kaleido_platform_cms_build.verifier_withdraw_batch[0].bytecode

  lifecycle {
    precondition {
      condition     = length(lookup(local.verifier_mismatches, local.verifier_contracts.withdraw_batch, [])) == 0
      error_message = "${local.verifier_contracts.withdraw_batch} in the contracts archive does not match withdraw_batch-vkey.json in the proving keys archive, so it would reject the nodes' proofs. Use contracts and proving keys from the same Zeto release or trusted setup."
    }
  }
}

resource "kaleido_platform_evm_connector_contract_deploy" "zeto_anon_impl" {
  count = local.deploy ? 1 : 0

  environment = var.environment_id
  service     = var.connector_service_id
  api         = var.connector_api_name
  key         = local.signing_identity
  abi         = kaleido_platform_cms_build.zeto_anon[0].abi
  bytecode    = kaleido_platform_cms_build.zeto_anon[0].bytecode
}

resource "kaleido_platform_evm_connector_contract_deploy" "factory_impl" {
  count = local.deploy ? 1 : 0

  environment = var.environment_id
  service     = var.connector_service_id
  api         = var.connector_api_name
  key         = local.signing_identity
  abi         = kaleido_platform_cms_build.zeto_factory[0].abi
  bytecode    = kaleido_platform_cms_build.zeto_factory[0].bytecode
}

resource "kaleido_platform_evm_connector_contract_deploy" "factory_proxy" {
  count = local.deploy ? 1 : 0

  environment = var.environment_id
  service     = var.connector_service_id
  api         = var.connector_api_name
  key         = local.signing_identity
  abi         = kaleido_platform_cms_build.zeto_factory_proxy[0].abi
  bytecode    = kaleido_platform_cms_build.zeto_factory_proxy[0].bytecode

  # ERC1967Proxy constructor args, keyed by input name (the connector's deploy
  # operation requires params as an object): implementation + initializer
  # calldata. ZetoFactory's initializer takes no arguments (default 0x8129fc1c =
  # initialize()); it makes the deployer the factory owner, which is required to
  # register token implementations below.
  params_json = jsonencode({
    implementation = kaleido_platform_evm_connector_contract_deploy.factory_impl[0].contract_address
    _data          = var.factory_initializer_selector
  })
}

# Registers the Zeto_Anon token implementation and its verifiers with the factory, under
# the name the domain config references. Owner-only, so it is signed by the deployer.
# Zeto_Anon has no lock/burn support, so those verifiers are left unset.
resource "kaleido_platform_evm_connector_contract_invoke" "register_zeto_anon" {
  count = local.deploy ? 1 : 0

  environment = var.environment_id
  service     = var.connector_service_id
  api         = var.connector_api_name
  key         = local.signing_identity
  to          = kaleido_platform_evm_connector_contract_deploy.factory_proxy[0].contract_address
  abi         = kaleido_platform_cms_build.zeto_factory[0].abi
  method      = "registerImplementation"

  params_json = jsonencode({
    name = "Zeto_Anon"
    implementation = {
      implementation = kaleido_platform_evm_connector_contract_deploy.zeto_anon_impl[0].contract_address
      verifiers = {
        verifier              = kaleido_platform_evm_connector_contract_deploy.verifier_anon[0].contract_address
        depositVerifier       = kaleido_platform_evm_connector_contract_deploy.verifier_deposit[0].contract_address
        withdrawVerifier      = kaleido_platform_evm_connector_contract_deploy.verifier_withdraw[0].contract_address
        lockVerifier          = local.zero_address
        burnVerifier          = local.zero_address
        batchVerifier         = kaleido_platform_evm_connector_contract_deploy.verifier_anon_batch[0].contract_address
        batchWithdrawVerifier = kaleido_platform_evm_connector_contract_deploy.verifier_withdraw_batch[0].contract_address
        batchLockVerifier     = local.zero_address
        batchBurnVerifier     = local.zero_address
      }
    }
  })
}

locals {
  factory_address = !local.deploy ? var.factory_address : try(
    kaleido_platform_evm_connector_contract_deploy.factory_proxy[0].contract_address, null
  )
}
