output "factory_address" {
  value       = local.factory_address
  description = "Address of the ERC1967 proxy pente factory on the base ledger."
}

output "domain" {
  value = {
    pente = {
      plugin = {
        type    = "jar"
        library = "/app/domains/pente.jar"
        class   = var.plugin_class
      }
      registryAddress = local.factory_address
    }
  }
  description = "Domain config."
}

output "build_ids" {
  value = merge(
    { for b in kaleido_platform_cms_build.pente : "pente" => b.id },
    { for b in kaleido_platform_cms_build.pente_factory : "pente_factory" => b.id },
    { for b in kaleido_platform_cms_build.pente_factory_proxy : "pente_factory_proxy" => b.id },
  )
  description = "IDs of the ContractManager resources keyed by contract."
}
