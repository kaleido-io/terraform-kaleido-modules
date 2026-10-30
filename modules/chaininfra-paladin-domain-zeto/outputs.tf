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
          implementations = [
            for name, impl in local.implementations : { name = name, circuits = impl.circuits }
          ]
        }
        snarkProver = {
          circuitsDir    = var.snark_prover_dir
          provingKeysDir = var.snark_prover_dir
        }
      }
    }
  }
  description = "Domain config"

  # Nodes must not be configured with the factory until the implementations are registered on it
  depends_on = [kaleido_platform_evm_connector_contract_invoke.register]
}

output "node_zeto_artifacts" {
  value = {
    proving_keys_archive_url = var.proving_keys_archive_url
    circuits_archive_url     = var.circuits_archive_url
    circuits                 = sort(local.circuits)
  }
  description = "Zeto proving keys and circuits each Paladin node needs, with the circuits the implementations prove with. For the platform to install on the nodes; not yet consumed by chaininfra-paladin-node."
}

output "build_ids" {
  value = merge(
    { for b in kaleido_platform_cms_build.zeto_factory : "zeto_factory" => b.id },
    { for b in kaleido_platform_cms_build.zeto_factory_proxy : "zeto_factory_proxy" => b.id },
    { for k, b in kaleido_platform_cms_build.implementation : local.implementations[k].build_name => b.id },
    { for k, b in kaleido_platform_cms_build.verifier : "verifier_${k}" => b.id },
    { for k, b in kaleido_platform_cms_build.library : "library_${k}" => b.id },
  )
  description = "IDs of the ContractManager resources keyed by contract."
}
