# ─── Client jars in the artifact registry ─────────────────────────────────────
#
# The vendor's jars are uploaded to an artifact registry namespace of the 'jar' family, the service is
# granted that namespace, and its jmsClientJars file set references them.

resource "kaleido_platform_ars_namespace" "jars" {
  count = var.create_registry_namespace ? 1 : 0

  environment       = var.environment_id
  service           = var.registry_service_id
  name              = var.registry_namespace
  artifact_family   = "jar"
  auto_create_repos = true
  description       = "JMS client jars for ${var.connector_name}"
}

resource "kaleido_platform_ars_file_tag" "jars" {
  for_each = local.uploaded_jars

  environment = var.environment_id
  service     = var.registry_service_id
  namespace   = var.create_registry_namespace ? kaleido_platform_ars_namespace.jars[0].name : var.registry_namespace
  name        = each.value.name
  file_path   = each.value.file_path
  type        = "jar"
  version     = each.value.version
  tag         = each.value.tag
}

# ─── Runtime + Service ────────────────────────────────────────────────────────
#
# The JMS connector has no dedicated stack type, so the runtime and service are created without a
# stack. A WorkflowEngine service must exist in the environment; the platform auto-binds it to the
# connector (it is not expressed in config here).

resource "kaleido_platform_runtime" "this" {
  type        = "JMSConnectorRuntime"
  name        = var.connector_name
  environment = var.environment_id
  size        = var.runtime_size
  zone        = var.runtime_zone
  config_json = jsonencode({})
}

resource "kaleido_platform_service" "this" {
  type               = "JMSConnectorService"
  name               = var.connector_name
  environment        = var.environment_id
  runtime            = kaleido_platform_runtime.this.id
  registry_namespace = var.create_registry_namespace ? kaleido_platform_ars_namespace.jars[0].name : var.registry_namespace

  config_json = jsonencode(local.config_json)
  cred_sets   = local.cred_sets
  file_sets   = local.file_sets
}

# ─── Config assembly ──────────────────────────────────────────────────────────
#
# Secrets go in credential sets and files in file sets, each referenced from the config by name
# ({ credSetRef = "<cred set>" }, { fileRef = "#<file set>.<file>" }). The set names match the ones the
# console uses. The service config's schema rejects explicit nulls, so unset keys are dropped with the
# `merge([for k, v in {...} : { (k) = v } if v != null]...)` idiom.

locals {
  jar_files     = { for j in var.client_jars : basename(j.name) => j }
  uploaded_jars = { for file, j in local.jar_files : file => j if j.file_path != null }

  # Only the names of secrets reach the config, so it stays readable in plans.
  secret_property_names = nonsensitive(toset(keys(var.secret_properties)))
  jndi_secret_env_names = nonsensitive(toset(keys(var.jndi_secret_environment)))
  has_broker_auth       = nonsensitive(var.broker_auth != null)
  has_jndi_auth         = nonsensitive(var.jndi_auth != null)
  has_jndi              = var.connection_factory.jndi != null
  has_tls               = var.tls != null

  # Credential set names allow letters, digits, '.', '_' and '-'; file set names no '.', because a
  # fileRef splits "#<file set>.<file>" at the first one.
  secret_cred_set = { for p in local.secret_property_names : p => "jmsSecret-${replace(p, "/[^0-9A-Za-z._-]+/", "-")}" }
  jndi_cred_set   = { for p in local.jndi_secret_env_names : p => "jndiSecret-${replace(p, "/[^0-9A-Za-z._-]+/", "-")}" }
  file_set        = { for p, path in var.file_properties : p => "jmsFile-${replace(p, "/[^0-9A-Za-z_-]+/", "-")}" }
  jndi_file_set   = { for p, path in var.jndi_file_environment : p => "jndiFile-${replace(p, "/[^0-9A-Za-z_-]+/", "-")}" }

  jndi_block = !local.has_jndi ? null : merge([
    for k, v in {
      initialContextFactory = var.connection_factory.jndi.initialContextFactory
      connectionFactoryName = var.connection_factory.jndi.connectionFactoryName
      providerUrl           = var.connection_factory.jndi.providerUrl
      lookupDestinations    = var.connection_factory.jndi.lookupDestinations
      environment           = var.connection_factory.jndi.environment
      objectFactories       = var.connection_factory.jndi.objectFactories
      secretEnvironment     = length(local.jndi_cred_set) == 0 ? null : { for p, cs in local.jndi_cred_set : p => { credSetRef = cs } }
      fileEnvironment       = length(local.jndi_file_set) == 0 ? null : { for p, fs in local.jndi_file_set : p => { fileRef = "#${fs}.${basename(var.jndi_file_environment[p])}" } }
      auth                  = local.has_jndi_auth ? { credSetRef = "jndiAuth" } : null
      bindings              = var.jndi_bindings_file != null ? { fileRef = "#jndiBindings..bindings" } : null
    } : { (k) = v } if v != null
  ]...)

  connection_factory = merge([
    for k, v in {
      className        = var.connection_factory.className
      jndi             = local.jndi_block
      properties       = var.connection_factory.properties
      secretProperties = length(local.secret_cred_set) == 0 ? null : { for p, cs in local.secret_cred_set : p => { credSetRef = cs } }
      fileProperties   = length(local.file_set) == 0 ? null : { for p, fs in local.file_set : p => { fileRef = "#${fs}.${basename(var.file_properties[p])}" } }
    } : { (k) = v } if v != null
  ]...)

  tls_block = !local.has_tls ? null : merge([
    for k, v in {
      enabled = var.tls.enabled
      ca      = var.tls.ca_pem != null ? { fileRef = "#jmsTls.ca.crt" } : null
      cert    = var.tls.cert_pem != null ? { fileRef = "#jmsTls.tls.crt" } : null
      key     = var.tls.key_pem != null ? { fileRef = "#jmsTls.tls.key" } : null
    } : { (k) = v } if v != null
  ]...)

  config_json = merge([
    for k, v in {
      connectionFactory = local.connection_factory
      clientJars        = [for j in var.client_jars : { fileRef = "#jmsClientJars.${basename(j.name)}" }]
      auth              = local.has_broker_auth ? { credSetRef = "jmsBrokerAuth" } : null
      tls               = local.tls_block
      producer          = var.producer
    } : { (k) = v } if v != null
  ]...)

  cred_sets = merge(
    local.has_broker_auth ? {
      jmsBrokerAuth = {
        type       = "basic_auth"
        basic_auth = { username = var.broker_auth.username, password = var.broker_auth.password }
      }
    } : {},
    local.has_jndi_auth ? {
      jndiAuth = {
        type       = "basic_auth"
        basic_auth = { username = var.jndi_auth.username, password = var.jndi_auth.password }
      }
    } : {},
    { for p, cs in local.secret_cred_set : cs => { type = "key", key = { value = var.secret_properties[p] } } },
    { for p, cs in local.jndi_cred_set : cs => { type = "key", key = { value = var.jndi_secret_environment[p] } } },
  )

  file_sets = merge(
    {
      jmsClientJars = {
        files = {
          for file, j in local.jar_files : file => {
            type              = "jar"
            registry_file_ref = j.file_path != null ? kaleido_platform_ars_file_tag.jars[file].registry_file_ref : j.registry_file_ref
          }
        }
      }
    },
    # Vendor files (key stores, CCDTs, .bindings) are opaque binaries, so they go as base64.
    { for p, fs in local.file_set : fs => { files = { (basename(var.file_properties[p])) = { type = "opaque", data = { base64 = filebase64(var.file_properties[p]) } } } } },
    { for p, fs in local.jndi_file_set : fs => { files = { (basename(var.jndi_file_environment[p])) = { type = "opaque", data = { base64 = filebase64(var.jndi_file_environment[p]) } } } } },
    var.jndi_bindings_file != null ? {
      jndiBindings = { files = { ".bindings" = { type = "opaque", data = { base64 = filebase64(var.jndi_bindings_file) } } } }
    } : {},
    local.has_tls && (var.tls.ca_pem != null || var.tls.cert_pem != null) ? {
      jmsTls = {
        files = merge(
          var.tls.ca_pem != null ? { "ca.crt" = { type = "pem", data = { text = var.tls.ca_pem } } } : {},
          var.tls.cert_pem != null ? { "tls.crt" = { type = "pem", data = { text = var.tls.cert_pem } } } : {},
          var.tls.key_pem != null ? { "tls.key" = { type = "pem", data = { text = var.tls.key_pem } } } : {},
        )
      }
    } : {},
  )
}
