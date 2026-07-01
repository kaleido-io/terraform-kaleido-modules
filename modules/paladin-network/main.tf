resource "kaleido_platform_network" "this" {
  environment = var.environment_id
  name        = var.network_name
  type        = "PaladinNetwork"

  config_json = jsonencode({})
}
