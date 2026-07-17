# --- Blockchain Application Firewall Stack ─────────────────────────────────────────────────

locals {
  policies = {
    for i, policy in var.policies : i => {
      policy         = policy.file != null ? file(policy.file) : policy.rego
      application_id = policy.application_id
    }
  }
}

resource "kaleido_platform_runtime" "this" {
  type = "EVMGateway"
  name = "${var.stack_name}-gateway"
  stack_id = kaleido_platform_stack.this.id
  environment = var.environment_id
  config_json = jsonencode({})

  size = var.runtime_size
}

resource "kaleido_platform_service" "this" {
  type = "EVMGateway"
  name = "${var.stack_name}-gateway"
  runtime = kaleido_platform_runtime.this.id
  environment = var.environment_id
  stack_id = kaleido_platform_stack.this.id
  config_json = jsonencode({
    decodeRawTransactions = true,
    fineGrainedPermissions = true,
    network = {
      id = var.network_id
    }
  })
}

resource "kaleido_platform_hostname" "this" {
  name = "${var.stack_name}-gateway"
  environment = var.environment_id
  service = kaleido_platform_service.this.id
  hostname = var.hostname
  endpoints = ["jsonrpc", "jsonrpcws", "graphql"]
  mtls = false
  count = var.hostname != null ? 1 : 0
}

resource "kaleido_platform_stack" "this" {
  environment = var.environment_id
  name        = var.stack_name
  type        = "chain_infrastructure"
  sub_type = "BAFStack"
  network_id  = var.network_id
}

## Apply the policy to the applications specified in the input
resource "kaleido_platform_service_access_policy" "this" {
  for_each = local.policies
  service_id = kaleido_platform_service.this.id
  policy = each.value.policy
  application_id = each.value.application_id
}