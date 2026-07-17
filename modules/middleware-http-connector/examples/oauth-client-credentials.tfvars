# HTTP connector to a backend protected by OAuth 2.0 client-credentials.
# The connector fetches and caches a bearer token from tokenURL and injects it
# into every backend request.

connector_name = "http-connector"

url = "https://backend.example.com/api"

oauth = {
  enabled  = true
  tokenURL = "https://idp.example.com/oauth2/token"
  authType = "client_secret_basic"
  clientId = "my-client-id"
  scopes   = ["backend.read", "backend.write"]

  client_secret = "change-me"

  cache = {
    ttl          = "1h"
    refreshAhead = "5m"
  }
}
