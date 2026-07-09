output "factory_address" {
  value       = local.factory_address
  description = "Address of the network's pente factory (the ERC1967 proxy — the address the plugin talks to): the deployed proxy in deploy mode, or existing_factory_address passed through in existing mode. Publish this to joiner accounts as their existing_factory_address."
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
      # No config block — pente has no domain config.
    }
  }
  description = "Ready-to-merge baseConfig.domains fragment for chaininfra-paladin-node: domains = merge(module.pente.domain, ...). In deploy mode it references the deploy action's contract_address, so consuming nodes implicitly wait for the factory to be mined — no depends_on needed."
}

output "build_ids" {
  value = merge(
    { for b in kaleido_platform_cms_build.pente : "pente" => b.id },
    { for b in kaleido_platform_cms_build.pente_factory : "pente_factory" => b.id },
    { for b in kaleido_platform_cms_build.pente_factory_proxy : "pente_factory_proxy" => b.id },
  )
  description = "IDs of the cms_build resources keyed by contract (pente, pente_factory, pente_factory_proxy) — for app-level invoke/indexing reuse. Empty when create_builds = false."
}
