output "factory_address" {
  value       = local.factory_address
  description = "Address of the ERC1967 proxy noto factory." 
}

output "domain" {
  value = {
    noto = {
      plugin          = { type = "c-shared", library = "/app/domains/libnoto.so" }
      registryAddress = local.factory_address
      config = { factoryVersion = 2 }
    }
  }
  description = "Domain config"
}

output "build_ids" {
  value = merge(
    { for b in kaleido_platform_cms_build.noto : "noto" => b.id },
    { for b in kaleido_platform_cms_build.noto_factory : "noto_factory" => b.id },
    { for b in kaleido_platform_cms_build.noto_factory_proxy : "noto_factory_proxy" => b.id },
    { for b in kaleido_platform_cms_build.atom : "atom" => b.id },
    { for b in kaleido_platform_cms_build.atom_factory : "atom_factory" => b.id },
    { for b in kaleido_platform_cms_build.identity_registry : "identity_registry" => b.id },
  )
  description = "IDs of the ContractManager resources keyed by contract."
}
