# Public half of the private_key_jwt signing key, to register with the identity
# provider (PingOne) under the configured `kid`. Only present when the HTTP connector
# uses the private_key_jwt grant. The private half never leaves Terraform state.

output "http_connector_oauth_public_key_pem" {
  description = "RSA public key (PEM, SubjectPublicKeyInfo) to register with the IdP for the private_key_jwt grant."
  value       = try(tls_private_key.http_oauth_signing[0].public_key_pem, null)
}

output "http_connector_oauth_public_key_openssh" {
  description = "Same RSA public key in OpenSSH format (convenience)."
  value       = try(tls_private_key.http_oauth_signing[0].public_key_openssh, null)
}

output "http_connector_oauth_signing_kid" {
  description = "The `kid` the assertion is signed with; must match the public key registered at the IdP."
  # kid is a non-secret key identifier; unwrap the sensitivity inherited from the http_oauth variable.
  value = nonsensitive(try(var.http_oauth.jwt.kid, null))
}
