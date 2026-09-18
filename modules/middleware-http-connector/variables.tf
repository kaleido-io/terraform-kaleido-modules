variable "environment_id" {
  type        = string
  description = "ID of the environment to deploy the HTTP connector into. A WorkflowEngine service must already exist in this environment — the platform auto-binds it to the HTTP connector."
}

variable "runtime_size" {
  type        = string
  default     = "Small"
  description = "Size of the HTTPConnector runtime."
}

variable "runtime_zone" {
  type        = string
  default     = null
  description = "Zone of the HTTPConnector runtime."
}

variable "connector_name" {
  type        = string
  default     = "http-connector"
  description = "Name of the HTTPConnector runtime and service."
}

variable "database_name" {
  type        = string
  default     = null
  description = "Optional external database name. The HTTP connector does not require a database; leave unset on managed-database instances."
}

# ─── Backend connection ───────────────────────────────────────────────────────

variable "url" {
  type        = string
  description = "Backend base URL. Event batches are POSTed here; request actions resolve their path relative to it. (config.url)"
}

# Connection-level HTTP client settings, inlined at the top level of the service
# config (ffresty connection config: retry / throttle / timeouts / pooling).
variable "connection" {
  type = object({
    throttle = optional(object({
      burst             = optional(number)
      requestsPerSecond = optional(number)
    }))
    retry = optional(object({
      enabled              = optional(bool)
      count                = optional(number)
      initWaitTime         = optional(string)
      maxWaitTime          = optional(string)
      errorStatusCodeRegex = optional(string)
    }))
    requestTimeout    = optional(string)
    idleTimeout       = optional(string)
    maxIdleConns      = optional(number)
    maxConnsPerHost   = optional(number)
    connectionTimeout = optional(string)
  })
  default     = {}
  description = "Connection-level HTTP client tuning (retry, throttle, timeouts, connection pooling). Durations are strings (e.g. \"30s\", \"5m\"). Note: the connector defaults retry on unless you set retry.enabled = false."
}

# Endpoint-level HTTP client settings, inlined at the top level of the service config.
variable "endpoint" {
  type = object({
    headers                   = optional(map(string))
    passthroughHeadersEnabled = optional(bool)
    proxy = optional(object({
      url = optional(string)
    }))
  })
  default     = {}
  description = "Endpoint-level HTTP client settings: static headers added to every backend request, passthrough-header enablement, and an optional forward proxy. A static \"Authorization\" header is mutually exclusive with oauth."
}

variable "backend_auth" {
  type = object({
    username = string
    password = string
  })
  default     = null
  sensitive   = true
  description = "Optional HTTP basic-auth credentials for the backend. When set, the module registers them as a credSet named 'backend_auth' on the service and references it from the config (auth.credSetRef = \"backend_auth\"). Mutually exclusive with oauth and a static Authorization header."
}

variable "backend_tls" {
  type = object({
    ca_pem               = optional(string)
    cert_pem             = optional(string)
    key_pem              = optional(string)
    insecure_skip_verify = optional(bool)
  })
  default     = null
  description = "Optional TLS / mutual-TLS to the backend. PEM contents are stored in a 'backend-tls' file set on the service and referenced from config.tls. Provide ca_pem for a custom CA, and cert_pem + key_pem for a client certificate (mTLS)."
}

# ─── OAuth 2.0 client-credentials injection ───────────────────────────────────

variable "oauth" {
  type = object({
    enabled  = optional(bool, true)
    tokenURL = optional(string)
    # authType: one of client_secret_basic | client_secret_post | tls_client_auth |
    # private_key_jwt | client_secret_jwt (default client_secret_basic).
    authType = optional(string)
    scopes   = optional(list(string))
    clientId = optional(string)
    # OAuth client secret for the client_secret_* grants. Registered as a 'key' credSet
    # named 'oauth_client_secret'; referenced from config as oauth.clientSecret.credSetRef.
    client_secret = optional(string)
    # TLS for the token endpoint. For the tls_client_auth grant, cert_pem + key_pem ARE the
    # client credential and are required. Stored in an 'oauth-tls' file set.
    tls = optional(object({
      ca_pem               = optional(string)
      cert_pem             = optional(string)
      key_pem              = optional(string)
      insecure_skip_verify = optional(bool)
    }))
    # JWT client assertion for the private_key_jwt / client_secret_jwt grants. For
    # private_key_jwt, private_key_pem IS the client credential and is required; it is
    # stored in an 'oauth-jwt' file set. client_secret_jwt signs with client_secret instead,
    # so it needs no key here.
    jwt = optional(object({
      private_key_pem = optional(string)
      kid             = optional(string)
      algorithm       = optional(string)
      audience        = optional(string)
      expiry          = optional(string)
      clockSkew       = optional(string)
    }))
    retry = optional(object({
      enabled              = optional(bool)
      count                = optional(number)
      initWaitTime         = optional(string)
      maxWaitTime          = optional(string)
      errorStatusCodeRegex = optional(string)
    }))
    throttle = optional(object({
      burst             = optional(number)
      requestsPerSecond = optional(number)
    }))
    proxy = optional(object({
      url = optional(string)
    }))
    cache = optional(object({
      ttl          = optional(string)
      refreshAhead = optional(string)
    }))
  })
  default     = null
  sensitive   = true
  description = "Optional OAuth 2.0 client-credentials bearer injection on backend requests (config.oauth). Requires tokenURL and clientId. client_secret is required for the client_secret_basic/client_secret_post/client_secret_jwt grants; tls.cert_pem + tls.key_pem are required for tls_client_auth; jwt.private_key_pem is required for private_key_jwt. Mutually exclusive with backend_auth and a static Authorization header."
}


# ─── Self-signed bearer JWT injection ─────────────────────────────────────────

variable "jwt_auth" {
  type = object({
    issuer          = string
    subject         = string
    audience        = optional(string)
    private_key_pem = string
    kid             = optional(string)
    algorithm       = optional(string)
    expiry          = optional(string)
    claims          = optional(map(string))
    cache           = optional(object({ refresh_ahead = optional(string) }))
  })
  default     = null
  sensitive   = true
  description = "Optional self-signed bearer JWT injection on backend requests (config.jwt). The connector signs its own JWT from issuer/subject/audience with private_key_pem (stored in a 'jwt-auth' file set) and injects it as Authorization: Bearer <jwt>, reusing it until expiry rather than minting one per request. Mutually exclusive with backend_auth, oauth, and a static Authorization header."

  validation {
    condition = length(compact([
      var.backend_auth != null ? "backend_auth" : "",
      var.oauth != null && try(var.oauth.enabled, true) ? "oauth" : "",
      var.jwt_auth != null ? "jwt_auth" : "",
      contains(keys(var.endpoint.headers == null ? {} : var.endpoint.headers), "Authorization") ? "header" : "",
    ])) <= 1
    error_message = "backend_auth, oauth, jwt_auth, and a static Authorization header (endpoint.headers[\"Authorization\"]) are mutually exclusive — set at most one."
  }
}
