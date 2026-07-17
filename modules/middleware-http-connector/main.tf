# ─── Runtime + Service ────────────────────────────────────────────────────────
#
# The HTTP connector has no dedicated stack type, so the runtime and service are
# created without a stack. A WorkflowEngine service must exist in the environment;
# the platform auto-binds it to the connector (it is not expressed in config here).

resource "kaleido_platform_runtime" "this" {
  type        = "HTTPConnector"
  name        = var.connector_name
  environment = var.environment_id
  size        = var.runtime_size
  zone        = var.runtime_zone
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "this" {
  type        = "HTTPConnector"
  name        = var.connector_name
  environment = var.environment_id
  runtime     = kaleido_platform_runtime.this.id

  config_json   = jsonencode(local.config_json)
  cred_sets     = local.cred_sets
  file_sets     = local.file_sets
  database_name = var.database_name
}

# ─── Config assembly ──────────────────────────────────────────────────────────
#
# The connection- and endpoint-level HTTP client settings are inlined at the top
# level of the service config; auth/oauth/tls are nested. Backend basic-auth and the
# OAuth client secret are supplied via credSets and referenced by name. TLS material is
# supplied via file sets and referenced as "#<file-set>.<file>".

locals {
  has_backend_auth = var.backend_auth != null
  has_oauth        = var.oauth != null && try(var.oauth.enabled, true)
  has_oauth_secret = local.has_oauth && try(var.oauth.client_secret, null) != null
  has_backend_tls  = var.backend_tls != null
  has_oauth_tls    = local.has_oauth && try(var.oauth.tls, null) != null

  # Build the service config, stripping null fields at every level. The connector's JSON
  # schema types nested blocks strictly (no nullables), so an explicit null is rejected —
  # any key that isn't set must be omitted entirely. The
  # `merge([for k, v in {...} : { (k) = v } if v != null]...)` idiom drops null keys while
  # preserving heterogeneous value types; a whole sub-object collapses to null (and is
  # dropped by its parent) when its source is unset, and an all-null object becomes `{}`.

  conn_throttle = var.connection.throttle == null ? null : merge([
    for k, v in {
      burst             = var.connection.throttle.burst
      requestsPerSecond = var.connection.throttle.requestsPerSecond
    } : { (k) = v } if v != null
  ]...)

  conn_retry = var.connection.retry == null ? null : merge([
    for k, v in {
      enabled              = var.connection.retry.enabled
      count                = var.connection.retry.count
      initWaitTime         = var.connection.retry.initWaitTime
      maxWaitTime          = var.connection.retry.maxWaitTime
      errorStatusCodeRegex = var.connection.retry.errorStatusCodeRegex
    } : { (k) = v } if v != null
  ]...)

  endpoint_proxy = var.endpoint.proxy == null ? null : merge([
    for k, v in { url = var.endpoint.proxy.url } : { (k) = v } if v != null
  ]...)

  backend_tls = !local.has_backend_tls ? null : merge([
    for k, v in {
      ca                 = var.backend_tls.ca_pem != null ? { fileRef = "#backend-tls.ca.crt" } : null
      cert               = var.backend_tls.cert_pem != null ? { fileRef = "#backend-tls.tls.crt" } : null
      key                = var.backend_tls.key_pem != null ? { fileRef = "#backend-tls.tls.key" } : null
      insecureSkipVerify = var.backend_tls.insecure_skip_verify
    } : { (k) = v } if v != null
  ]...)

  oauth_tls = !local.has_oauth_tls ? null : merge([
    for k, v in {
      ca                 = var.oauth.tls.ca_pem != null ? { fileRef = "#oauth-tls.ca.crt" } : null
      cert               = var.oauth.tls.cert_pem != null ? { fileRef = "#oauth-tls.tls.crt" } : null
      key                = var.oauth.tls.key_pem != null ? { fileRef = "#oauth-tls.tls.key" } : null
      insecureSkipVerify = var.oauth.tls.insecure_skip_verify
    } : { (k) = v } if v != null
  ]...)

  oauth_retry = try(var.oauth.retry, null) == null ? null : merge([
    for k, v in {
      enabled              = var.oauth.retry.enabled
      count                = var.oauth.retry.count
      initWaitTime         = var.oauth.retry.initWaitTime
      maxWaitTime          = var.oauth.retry.maxWaitTime
      errorStatusCodeRegex = var.oauth.retry.errorStatusCodeRegex
    } : { (k) = v } if v != null
  ]...)

  oauth_throttle = try(var.oauth.throttle, null) == null ? null : merge([
    for k, v in {
      burst             = var.oauth.throttle.burst
      requestsPerSecond = var.oauth.throttle.requestsPerSecond
    } : { (k) = v } if v != null
  ]...)

  oauth_proxy = try(var.oauth.proxy, null) == null ? null : merge([
    for k, v in { url = var.oauth.proxy.url } : { (k) = v } if v != null
  ]...)

  oauth_cache = try(var.oauth.cache, null) == null ? null : merge([
    for k, v in {
      ttl          = var.oauth.cache.ttl
      refreshAhead = var.oauth.cache.refreshAhead
    } : { (k) = v } if v != null
  ]...)

  oauth_block = !local.has_oauth ? null : merge([
    for k, v in {
      enabled      = true
      tokenURL     = var.oauth.tokenURL
      authType     = var.oauth.authType
      scopes       = var.oauth.scopes
      clientId     = var.oauth.clientId
      clientSecret = local.has_oauth_secret ? { credSetRef = "oauth_client_secret" } : null
      tls          = local.oauth_tls
      retry        = local.oauth_retry
      throttle     = local.oauth_throttle
      proxy        = local.oauth_proxy
      cache        = local.oauth_cache
    } : { (k) = v } if v != null
  ]...)

  config_json = merge([
    for k, v in {
      url                       = var.url
      throttle                  = local.conn_throttle
      retry                     = local.conn_retry
      requestTimeout            = var.connection.requestTimeout
      idleTimeout               = var.connection.idleTimeout
      maxIdleConns              = var.connection.maxIdleConns
      maxConnsPerHost           = var.connection.maxConnsPerHost
      connectionTimeout         = var.connection.connectionTimeout
      headers                   = var.endpoint.headers
      passthroughHeadersEnabled = var.endpoint.passthroughHeadersEnabled
      proxy                     = local.endpoint_proxy
      auth                      = local.has_backend_auth ? { credSetRef = "backend_auth" } : null
      tls                       = local.backend_tls
      oauth                     = local.oauth_block
    } : { (k) = v } if v != null
  ]...)

  cred_sets = merge(
    local.has_backend_auth ? {
      backend_auth = {
        type = "basic_auth"
        basic_auth = {
          username = var.backend_auth.username
          password = var.backend_auth.password
        }
      }
    } : {},
    local.has_oauth_secret ? {
      oauth_client_secret = {
        type = "key"
        key  = { value = var.oauth.client_secret }
      }
    } : {},
  )

  file_sets = merge(
    local.has_backend_tls ? {
      "backend-tls" = {
        files = merge(
          var.backend_tls.ca_pem != null ? { "ca.crt" = { type = "application/x-pem-file", data = { text = var.backend_tls.ca_pem } } } : {},
          var.backend_tls.cert_pem != null ? { "tls.crt" = { type = "application/x-pem-file", data = { text = var.backend_tls.cert_pem } } } : {},
          var.backend_tls.key_pem != null ? { "tls.key" = { type = "application/x-pem-file", data = { text = var.backend_tls.key_pem } } } : {},
        )
      }
    } : {},
    local.has_oauth_tls ? {
      "oauth-tls" = {
        files = merge(
          var.oauth.tls.ca_pem != null ? { "ca.crt" = { type = "application/x-pem-file", data = { text = var.oauth.tls.ca_pem } } } : {},
          var.oauth.tls.cert_pem != null ? { "tls.crt" = { type = "application/x-pem-file", data = { text = var.oauth.tls.cert_pem } } } : {},
          var.oauth.tls.key_pem != null ? { "tls.key" = { type = "application/x-pem-file", data = { text = var.oauth.tls.key_pem } } } : {},
        )
      }
    } : {},
  )
}
