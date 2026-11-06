# jms-connector

Deploys a JMS connector (`JMSConnectorRuntime` + `JMSConnectorService`) that connects the workflow
engine to a Jakarta Messaging (JMS 3.x) broker, such as IBM MQ, Solace PubSub+, ActiveMQ Artemis or
RabbitMQ. Streams and workflows use it through these handlers:

| Handler | Kind | Use |
|---------|------|-----|
| `jms.consumer` | Event source | A stream consumes a queue or topic |
| `jms` | Transaction handler | A workflow stage sends a message (`send`) |
| `jms.producer`, `jms.producer.<name>` | Event processors | A stream sends each of its events as a message |

You supply the broker vendor's client jars: the module uploads them to an artifact registry namespace,
or uses ones already there. The connector is **not** wrapped in a stack: the runtime and service are
created directly in the environment.

See the platform documentation for the connector: Integration gateway → Connectors → JMS.

## Prerequisites

- A **WorkflowEngine** service in the target environment. The platform auto-binds it to the JMS
  connector — there is no variable to wire it explicitly.
- An **artifact registry** service, for the client jars.
- The broker vendor's **Jakarta** (`jakarta.jms`) client jars and their runtime dependencies. Clients
  of the older `javax.jms` API can't be loaded.
- Version 1.3.5 or later of the Kaleido provider, for the artifact registry resources.

## Usage

```hcl
module "jms_connector" {
  source = "https://github.com/kaleido-io/terraform-kaleido-modules/modules/middleware-jms-connector?ref=main"

  environment_id      = kaleido_platform_environment.env.id
  registry_service_id = kaleido_platform_service.registry.id

  client_jars = [
    { name = "rabbitmq/rabbitmq-jms-3.4.0.jar", file_path = "jars/rabbitmq-jms-3.4.0.jar", tag = "3.4.0" },
    { name = "rabbitmq/amqp-client-5.22.0.jar", file_path = "jars/amqp-client-5.22.0.jar", tag = "5.22.0" },
  ]

  connection_factory = {
    className  = "com.rabbitmq.jms.admin.RMQConnectionFactory"
    properties = { host = "rabbitmq.example.com", port = "5672", virtualHost = "/" }
  }

  broker_auth = {
    username = "jmsapp"
    password = var.broker_password
  }
}
```

Or with one of the sample `*.tfvars` files:

```
terraform apply -var-file=modules/middleware-jms-connector/examples/rabbitmq.tfvars
```

| Example | Shows |
|---------|-------|
| [`rabbitmq.tfvars`](./examples/rabbitmq.tfvars) | Jars uploaded from local files, a class-name connection factory, a broker login |
| [`solace-static-producers.tfvars`](./examples/solace-static-producers.tfvars) | Jars already in a shared namespace, TLS with a private CA, static producers with `jms.producer` turned off |
| [`ibm-mq-jndi.tfvars`](./examples/ibm-mq-jndi.tfvars) | A connection factory looked up in a file-system JNDI `.bindings` file, with JNDI names for queues |

## Client jars

`client_jars` lists the jars, the vendor's client first. Each one is either:

- **Uploaded** from `file_path` to `registry_namespace` under `name`, a lowercase path such as
  `rabbitmq/amqp-client-5.22.0.jar`. Set `tag` for an explicit tag (tags are immutable, so changing the
  file needs a new tag), or `version` for a tag derived from the version and the file's checksum, which
  uploads the jar again whenever the file changes.
- **Already in the registry**: `registry_file_ref` is its `"<name>:<tag>"`.

By default the module creates `registry_namespace` (`jms-client-jars`) with the `jar` artifact family.
Set `create_registry_namespace = false` to use an existing one, for example a namespace several
connectors share.

## Connection factory

`connection_factory` mirrors the service config's `connectionFactory`, after Jakarta EE's
`@JMSConnectionFactoryDefinition`. Set exactly one of:

- `className`: the vendor's `jakarta.jms.ConnectionFactory`, with its settings in `properties`. The
  setting names are the vendor's, as in its documentation.
- `jndi`: look up a connection factory the messaging administrators bound in a naming service. The
  vendor's client jars are still needed. With `lookupDestinations = true`, the queue and topic names
  that streams, workflows and static producers use are JNDI names.

Secrets and files are separate variables, so they are kept out of the config:

| Variable | Stored as | Config |
|----------|-----------|--------|
| `broker_auth` | `basic_auth` credential set `jmsBrokerAuth` | `auth` |
| `secret_properties` | One `key` credential set per property, `jmsSecret-<property>` | `connectionFactory.secretProperties` |
| `file_properties` (property → local path) | One file set per property, `jmsFile-<property>` | `connectionFactory.fileProperties` |
| `jndi_auth` | `basic_auth` credential set `jndiAuth` | `connectionFactory.jndi.auth` |
| `jndi_secret_environment` | One `key` credential set per property, `jndiSecret-<property>` | `connectionFactory.jndi.secretEnvironment` |
| `jndi_file_environment` (property → local path) | One file set per property, `jndiFile-<property>` | `connectionFactory.jndi.fileEnvironment` |
| `jndi_bindings_file` (local path) | File set `jndiBindings` | `connectionFactory.jndi.bindings` |
| `tls` (PEM strings) | File set `jmsTls` | `tls` |

A service created here can also be edited in the console.

## TLS

`tls` turns on TLS to the broker with `ca_pem` for a broker certificate that isn't publicly trusted,
and `cert_pem` with `key_pem` for mutual TLS. Most vendors also need their own TLS setting in
`connection_factory.properties`, for example RabbitMQ's `useDefaultSslContext = "true"` with port 5671.

## Static producers

`producer` is passed through as the service config's `producer` block, with the config's camelCase
field names. Each `static` entry adds the event processor `jms.producer.<name>`, which sends every
event to one configured queue or topic. With `dynamicProducer = false`, `jms.producer` is not available,
so streams can only send to the static producers' destinations:

```hcl
producer = {
  dynamicProducer = false
  static = [
    { name = "acks", queue = "PAYMENTS.ACK", persistent = true, properties = { msgType = "ack" } },
    { name = "audit", queue = "PAYMENTS.AUDIT", messageFormat = "envelope" },
  ]
}
```

The platform checks the block when the service is created or updated. A stream uses a static producer
by naming `jms.producer.<name>` as its event processor, with the module's `provider_name` output as the
provider.

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ID of the JMSConnectorService |
| `service_name` | Name of the JMSConnectorService |
| `runtime_id` | ID of the JMSConnectorRuntime |
| `provider_name` | The provider name streams and workflows use: the service ID with `:` replaced by `-` |
| `registry_namespace` | Artifact registry namespace of the client jars |
