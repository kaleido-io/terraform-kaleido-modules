# http-connector

Deploys an HTTP connector (`HTTPConnector` runtime + service) that bridges the
platform to a single backend HTTP service: event batches are POSTed to the backend
and request actions resolve their path relative to its base URL.

Unlike the EVM/BTC connectors, the HTTP connector has no connector-manager config
types, flows, stream factories, or standard APIs — its entire behaviour is driven
by the typed service config below. It is also **not** wrapped in a stack: the runtime
and service are created directly in the environment.

## Prerequisites

A **WorkflowEngine** service must already exist in the target environment. The platform
auto-binds it to the HTTP connector — there is no variable to wire it explicitly.

## Usage

```hcl
module "http_connector" {
  source = "https://github.com/kaleido-io/terraform-kaleido-modules/modules/middleware-http-connector?ref=main"

  environment_id = kaleido_platform_environment.env.id

  url = "https://backend.example.com/api"

  backend_auth = {
    username = "svc-account"
    password = var.backend_password
  }
}
```

Or with one of the sample `*.tfvars` files:

```
terraform apply -var-file=modules/middleware-http-connector/examples/oauth-client-credentials.tfvars
```

## Authentication

Exactly one backend authentication mode should be configured — they are mutually exclusive:

| Mode | How |
|------|-----|
| HTTP basic auth | `backend_auth = { username, password }` → registered as a `basic_auth` credSet |
| OAuth 2.0 client-credentials | `oauth = { ... }` → bearer token fetched from `tokenURL` and injected |
| Static `Authorization` header | `endpoint.headers = { Authorization = "..." }` |

OAuth supports three client-authentication methods at the token endpoint via
`oauth.authType`: `client_secret_basic` (default), `client_secret_post`, and
`tls_client_auth`. The first two require `oauth.client_secret`; `tls_client_auth`
requires `oauth.tls.cert_pem` + `oauth.tls.key_pem`.

## TLS / mutual-TLS

`backend_tls` (and `oauth.tls` for the token endpoint) accept PEM contents directly.
The module stores them in a service file set and wires the config references:

```hcl
backend_tls = {
  ca_pem   = file("ca.pem")    # custom CA
  cert_pem = file("client.pem") # client cert (mTLS)
  key_pem  = file("client.key")
}
```

## Examples

Drop-in `*.tfvars` files under `examples/`:

| File | Notes |
|------|-------|
| `basic-auth.tfvars` | Backend with HTTP basic auth, headers, retry/throttle tuning |
| `oauth-client-credentials.tfvars` | Backend behind OAuth 2.0 client-credentials |

## Outputs

- `service_id`, `service_name`, `runtime_id`
