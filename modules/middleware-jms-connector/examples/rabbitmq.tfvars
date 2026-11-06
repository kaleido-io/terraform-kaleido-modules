# JMS connector to RabbitMQ, as in the platform docs' getting-started guide: RabbitMQ's JMS client and
# its AMQP client, uploaded from local files to the jms-client-jars registry namespace, and a
# broker login. Download the jars from Maven Central first.

connector_name      = "jmsconnect"
registry_service_id = "s:REPLACE_WITH_ARTIFACT_REGISTRY_SERVICE_ID"

client_jars = [
  { name = "rabbitmq/rabbitmq-jms-3.4.0.jar", file_path = "jars/rabbitmq-jms-3.4.0.jar", tag = "3.4.0" },
  { name = "rabbitmq/amqp-client-5.22.0.jar", file_path = "jars/amqp-client-5.22.0.jar", tag = "5.22.0" },
]

connection_factory = {
  className = "com.rabbitmq.jms.admin.RMQConnectionFactory"
  properties = {
    host        = "rabbitmq.example.com"
    port        = "5672"
    virtualHost = "/"
  }
}

broker_auth = {
  username = "jmsapp"
  password = "change-me"
}
