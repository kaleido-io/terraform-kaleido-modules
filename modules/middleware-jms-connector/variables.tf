variable "environment_id" {
  type        = string
  description = "ID of the environment to deploy the JMS connector into. A WorkflowEngine service must already exist in this environment — the platform auto-binds it to the JMS connector."
}

variable "runtime_size" {
  type        = string
  default     = "Small"
  description = "Size of the JMSConnectorRuntime."
}

variable "runtime_zone" {
  type        = string
  default     = null
  description = "Zone of the JMSConnectorRuntime."
}

variable "connector_name" {
  type        = string
  default     = "jms-connector"
  description = "Name of the JMSConnectorRuntime and service."
}

# ─── Client jars ──────────────────────────────────────────────────────────────

variable "registry_service_id" {
  type        = string
  default     = null
  description = "ID of the artifact registry service that holds the client jars. Required to create the registry namespace or upload jars."

  validation {
    condition     = var.registry_service_id != null || (!var.create_registry_namespace && alltrue([for j in var.client_jars : j.file_path == null]))
    error_message = "registry_service_id is required to create the registry namespace or upload client jars."
  }
}

variable "registry_namespace" {
  type        = string
  default     = "jms-client-jars"
  description = "Artifact registry namespace of the client jars. The service is granted access to it."
}

variable "create_registry_namespace" {
  type        = bool
  default     = true
  description = "Create registry_namespace (artifact family 'jar'). Set false to use a namespace that already exists, for example one shared by several connectors."
}

variable "client_jars" {
  type = list(object({
    name              = string
    file_path         = optional(string)
    version           = optional(string)
    tag               = optional(string)
    registry_file_ref = optional(string)
  }))
  description = <<-EOT
    The broker vendor's Jakarta Messaging client jars and their dependencies, the vendor's client first. (config.clientJars)
    Each entry is either uploaded or already in registry_namespace:
      - Upload: `name` is the path-style registry name (for example "rabbitmq/amqp-client-5.22.0.jar"), `file_path` the local jar,
        and exactly one of `version` (tagged "<version>-<sha8>", re-uploaded when the file changes) or `tag` (an explicit, immutable tag).
      - Existing: `name` as above and `registry_file_ref` as "<name>:<tag>".
    The file name in the service's jar file set is the last segment of `name`, so it must be unique.
  EOT

  validation {
    condition     = length(var.client_jars) > 0
    error_message = "client_jars needs at least one jar."
  }
  validation {
    condition     = alltrue([for j in var.client_jars : (j.file_path != null) != (j.registry_file_ref != null)])
    error_message = "Each client_jars entry needs exactly one of file_path (to upload it) or registry_file_ref (already in the registry)."
  }
  validation {
    condition     = alltrue([for j in var.client_jars : j.file_path == null || ((j.version != null) != (j.tag != null))])
    error_message = "Each uploaded client_jars entry needs exactly one of version or tag."
  }
  validation {
    condition     = length(distinct([for j in var.client_jars : basename(j.name)])) == length(var.client_jars)
    error_message = "The last segment of each client_jars name must be unique: it names the jar in the service's file set."
  }
}

# ─── Connection factory ───────────────────────────────────────────────────────

# Mirrors config.connectionFactory, as in Jakarta EE's @JMSConnectionFactoryDefinition: either the
# vendor's className with its properties, or a JNDI lookup of a factory the messaging administrators
# bound. Secrets and files for its properties are separate variables below.
variable "connection_factory" {
  type = object({
    className  = optional(string)
    properties = optional(map(string))
    jndi = optional(object({
      initialContextFactory = string
      connectionFactoryName = string
      providerUrl           = optional(string)
      lookupDestinations    = optional(bool)
      environment           = optional(map(string))
      objectFactories       = optional(list(string))
    }))
  })
  description = "The broker vendor's jakarta.jms.ConnectionFactory: className and its properties, or jndi to look up a factory in a naming service. With jndi, properties override settings on the looked-up factory. (config.connectionFactory)"

  validation {
    condition     = (var.connection_factory.className != null) != (var.connection_factory.jndi != null)
    error_message = "connection_factory needs exactly one of className or jndi."
  }
}

variable "secret_properties" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "Connection factory properties whose values are secrets, such as a key store password. Each is stored in a 'key' credential set named jmsSecret-<property>. Set the broker login with broker_auth. (config.connectionFactory.secretProperties)"
}

variable "file_properties" {
  type        = map(string)
  default     = {}
  description = "Connection factory properties that take a file, such as a key store or IBM MQ's CCDT: property name to local file path. Each file goes in a file set named jmsFile-<property>. (config.connectionFactory.fileProperties)"
}

variable "broker_auth" {
  type = object({
    username = string
    password = string
  })
  default     = null
  sensitive   = true
  description = "The user the connector logs in to the broker as, stored in the 'basic_auth' credential set jmsBrokerAuth. Leave unset for a broker that accepts connections without credentials. (config.auth)"
}

# ─── JNDI secrets and files ───────────────────────────────────────────────────

variable "jndi_auth" {
  type = object({
    username = string
    password = string
  })
  default     = null
  sensitive   = true
  description = "Naming service login, separate from broker_auth, stored in the 'basic_auth' credential set jndiAuth. Only with connection_factory.jndi. (config.connectionFactory.jndi.auth)"
}

variable "jndi_secret_environment" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "JNDI environment properties whose values are secrets, each in a 'key' credential set named jndiSecret-<property>. Only with connection_factory.jndi. (config.connectionFactory.jndi.secretEnvironment)"
}

variable "jndi_file_environment" {
  type        = map(string)
  default     = {}
  description = "JNDI environment properties that take a file: property name to local file path, each in a file set named jndiFile-<property>. Only with connection_factory.jndi. (config.connectionFactory.jndi.fileEnvironment)"
}

variable "jndi_bindings_file" {
  type        = string
  default     = null
  description = "Local path of a file-system JNDI .bindings file (for example from IBM MQ JMSAdmin), used with com.sun.jndi.fscontext.RefFSContextFactory instead of a provider URL. Stored in the file set jndiBindings. (config.connectionFactory.jndi.bindings)"
}

# ─── TLS ──────────────────────────────────────────────────────────────────────

variable "tls" {
  type = object({
    enabled  = optional(bool, true)
    ca_pem   = optional(string)
    cert_pem = optional(string)
    key_pem  = optional(string)
  })
  default     = null
  description = "TLS to the broker. ca_pem is the authority that signed the broker's certificate, when it isn't publicly trusted; cert_pem and key_pem are a client certificate for mutual TLS. The vendor's own TLS switch still goes in connection_factory.properties. Stored in the file set jmsTls. (config.tls)"

  validation {
    condition     = var.tls == null ? true : ((try(var.tls.cert_pem, null) == null) == (try(var.tls.key_pem, null) == null))
    error_message = "tls.cert_pem and tls.key_pem go together: set both for mutual TLS, or neither."
  }
}

# ─── Producers ────────────────────────────────────────────────────────────────

variable "producer" {
  type        = any
  default     = null
  description = <<-EOT
    The connector's event processors, exactly as config.producer: `dynamicProducer` (default true) makes jms.producer available,
    and each `static` entry adds jms.producer.<name>, which sends every event to one configured queue or topic. Field names
    are the service config's (camelCase), for example:
      { dynamicProducer = false, static = [{ name = "acks", queue = "PAYMENTS.ACK", properties = { msgType = "ack" } }] }
    The platform validates it when the service is created or updated. (config.producer)
  EOT
}
