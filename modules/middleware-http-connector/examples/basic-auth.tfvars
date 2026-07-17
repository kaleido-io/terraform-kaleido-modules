# HTTP connector to a backend secured with HTTP basic auth, with a couple of
# static headers and conservative retry/throttle tuning.

connector_name = "http-connector"

url = "https://backend.example.com/api"

connection = {
  requestTimeout = "30s"
  retry = {
    enabled = true
    count   = 5
  }
  throttle = {
    requestsPerSecond = 50
    burst             = 100
  }
}

endpoint = {
  headers = {
    "X-Tenant" = "acme"
  }
}

backend_auth = {
  username = "svc-account"
  password = "change-me"
}
