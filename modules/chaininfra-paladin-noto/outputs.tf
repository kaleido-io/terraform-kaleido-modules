output "factory_address" {
  value       = local.factory_address
  description = "Address of the network's noto factory (the ERC1967 proxy — the address the plugin talks to): the deployed proxy in deploy mode, or existing_factory_address passed through in existing mode. Publish this to joiner accounts as their existing_factory_address."
}

output "domain" {
  value = {
    noto = {
      plugin          = { type = "c-shared", library = "/app/domains/libnoto.so" }
      registryAddress = local.factory_address
      # 2 is the factory ABI generation of the pinned UUPS ("v2") contracts —
      # the plugin uses it to pick the factory ABI.
      config = { factoryVersion = 2 }
    }
  }
  description = "Ready-to-merge baseConfig.domains fragment for chaininfra-paladin-node: domains = merge(module.noto.domain, ...). In deploy mode it references the deploy action's contract_address, so consuming nodes implicitly wait for the factory to be mined — no depends_on needed."
}

output "build_ids" {
  value = merge(
    { for b in kaleido_platform_cms_build.noto : "noto" => b.id },
    { for b in kaleido_platform_cms_build.noto_factory : "noto_factory" => b.id },
    { for b in kaleido_platform_cms_build.noto_factory_proxy : "noto_factory_proxy" => b.id },
  )
  description = "IDs of the cms_build resources keyed by contract (noto, noto_factory, noto_factory_proxy) — for app-level invoke/indexing reuse. Empty when create_builds = false."
}
