output "network_id" {
  value       = kaleido_platform_network.this.id
  description = "ID of the created Paladin network."
}

output "network_name" {
  value       = kaleido_platform_network.this.name
  description = "Name of the created Paladin network."
}
