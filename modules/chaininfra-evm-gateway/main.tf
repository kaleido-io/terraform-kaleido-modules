# --- EVM Gateway runtime + service ─────────────────────────────────────────────────

resource "kaleido_platform_runtime" "this" {
  type = "EVMGateway"
  name = var.gateway_name
  stack_id = var.stack_id
  environment = var.environment_id
  config_json = jsonencode({})

  size = var.runtime_size
}

resource "kaleido_platform_service" "this" {
  type = "EVMGateway"
  name = var.gateway_name
  runtime = kaleido_platform_runtime.this.id
  environment = var.environment_id
  stack_id = var.stack_id
  config_json = jsonencode({
    network = {
      id = var.network_id
    }
  })
}

resource "kaleido_platform_hostname" "this" {
  name = var.gateway_name
  environment = var.environment_id
  service = kaleido_platform_service.this.id
  hostname = var.hostname
  endpoints = ["jsonrpc", "jsonrpcws", "graphql"]
  mtls = false
  count = var.hostname != null ? 1 : 0
}