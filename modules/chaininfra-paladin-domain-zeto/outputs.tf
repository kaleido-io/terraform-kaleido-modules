output "factory_address" {
  value       = local.factory_address
  description = "Address of the ERC1967 proxy zeto factory."
}

output "domain" {
  value = {
    zeto = {
      plugin          = { type = "c-shared", library = "/app/domains/libzeto.so" }
      registryAddress = local.factory_address
      allowSigning    = true
      config = {
        domainContracts = {
          implementations = [{
            name = "Zeto_Anon"
            circuits = {
              deposit        = { name = "deposit" }
              withdraw       = { name = "withdraw" }
              transfer       = { name = "anon" }
              transferLocked = { name = "anon" }
            }
          }]
        }
        snarkProver = {
          circuitsDir    = var.snark_prover_dir
          provingKeysDir = var.snark_prover_dir
        }
      }
    }
  }
  description = "Domain config"

  # Nodes must not be configured with the factory until Zeto_Anon is registered on it
  depends_on = [kaleido_platform_evm_connector_contract_invoke.register_zeto_anon]
}

output "node_zeto_artifacts" {
  value = {
    proving_keys_archive_url = var.proving_keys_archive_url
    circuits_archive_url     = var.circuits_archive_url
    circuits                 = keys(local.verifier_contracts)
  }
  description = "Zeto proving keys and circuits each Paladin node needs, with the circuits Zeto_Anon proves with. For the platform to install on the nodes; not yet consumed by chaininfra-paladin-node."
}

output "build_ids" {
  value = merge(
    { for b in kaleido_platform_cms_build.zeto_factory : "zeto_factory" => b.id },
    { for b in kaleido_platform_cms_build.zeto_factory_proxy : "zeto_factory_proxy" => b.id },
    { for b in kaleido_platform_cms_build.zeto_anon : "zeto_anon" => b.id },
    { for b in kaleido_platform_cms_build.verifier_anon : "verifier_anon" => b.id },
    { for b in kaleido_platform_cms_build.verifier_anon_batch : "verifier_anon_batch" => b.id },
    { for b in kaleido_platform_cms_build.verifier_deposit : "verifier_deposit" => b.id },
    { for b in kaleido_platform_cms_build.verifier_withdraw : "verifier_withdraw" => b.id },
    { for b in kaleido_platform_cms_build.verifier_withdraw_batch : "verifier_withdraw_batch" => b.id },
  )
  description = "IDs of the ContractManager resources keyed by contract."
}
