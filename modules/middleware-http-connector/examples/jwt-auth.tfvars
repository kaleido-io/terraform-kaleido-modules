# HTTP connector to a backend that accepts a self-signed bearer JWT instead of an
# OAuth token-endpoint round trip. The connector holds the private key, signs its
# own JWT with the claims below, and injects it as "Authorization: Bearer <jwt>" —
# reusing it until expiry rather than minting one per request.

connector_name = "http-connector"

url = "https://backend.example.com/api"

jwt_auth = {
  issuer          = "https://issuer.example.com"
  subject         = "my-client-id"
  private_key_pem = "-----BEGIN PRIVATE KEY-----\nchange-me\n-----END PRIVATE KEY-----\n"
  kid             = "2026-08-signing"
  algorithm       = "RS256"
  expiry          = "1h"

  claims = {
    aud_extra = "backend-api"
  }
}
