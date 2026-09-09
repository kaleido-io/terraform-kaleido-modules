# HTTP connector to a backend protected by OAuth 2.0 client-credentials, where the
# client authenticates to the token endpoint with a signed JWT assertion instead of
# a secret (private_key_jwt, RFC 7523 §2.2).
#
# Register the PUBLIC half of this key pair with the identity provider under the same
# kid. Only the private half goes to Kaleido, stored in an 'oauth-jwt' file set.

connector_name = "http-connector"

url = "https://backend.example.com/api"

oauth = {
  enabled  = true
  tokenURL = "https://idp.example.com/oauth2/token"
  authType = "private_key_jwt"
  clientId = "my-client-id"
  scopes   = ["backend.read", "backend.write"]

  jwt = {
    private_key_pem = "-----BEGIN PRIVATE KEY-----\nchange-me\n-----END PRIVATE KEY-----\n"
    kid             = "2026-08-signing"
    algorithm       = "RS256"
  }

  cache = {
    ttl          = "1h"
    refreshAhead = "5m"
  }
}
