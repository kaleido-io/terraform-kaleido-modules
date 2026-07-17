# ─── BlockIndexer runtime + service ─────────────────────────────────────────────────

resource "kaleido_platform_runtime" "this"{
  type = "BlockIndexer"
  name = var.block_indexer_name
  stack_id = var.stack_id
  environment = var.environment_id
  size = var.blockindexer_size
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "this"{
  type = "BlockIndexer"
  name = var.block_indexer_name
  environment = var.environment_id
  runtime = kaleido_platform_runtime.this.id
  config_json=jsonencode(
    {
      contractManager = {
        id = var.contract_manager_service_id
      }
      evmGateway = {
        id = var.evm_gateway_service_id
      }
    }
  )
  stack_id = var.stack_id
}

resource "kaleido_platform_hostname" "this" {
  name = var.hostname
  environment = var.environment_id
  service = kaleido_platform_service.this.id
  hostname = var.hostname
  endpoints = ["ui", "rest"]
  mtls = false
}