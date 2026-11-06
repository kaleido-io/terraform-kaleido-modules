# JMS connector to Solace PubSub+ with static producers: streams can only send to PAYMENTS.ACK and
# PAYMENTS.AUDIT, through jms.producer.acks and jms.producer.audit, because the dynamic jms.producer
# is turned off. The Solace jars are already in the shared jars namespace, so nothing is uploaded.

connector_name            = "solace-connector"
registry_namespace        = "java-jars"
create_registry_namespace = false

# Solace's Jakarta JMS client, then its runtime dependencies (abbreviated: list all of them, in order)
client_jars = [
  { name = "solace/sol-jms-jakarta-10.30.2.jar", registry_file_ref = "solace/sol-jms-jakarta-10.30.2.jar:10.30.2" },
  { name = "solace/solace-serdes-1.0.0.jar", registry_file_ref = "solace/solace-serdes-1.0.0.jar:1.0.0" },
  { name = "solace/commons-logging-1.2.jar", registry_file_ref = "solace/commons-logging-1.2.jar:1.2" },
]

connection_factory = {
  className = "com.solacesystems.jms.SolConnectionFactoryImpl"
  properties = {
    host               = "tcps://solace.example.com:55443"
    VPN                = "default"
    directTransport    = "false"
    browserTimeoutInMS = "500"
  }
}

broker_auth = {
  username = "jmsapp"
  password = "change-me"
}

tls = {
  ca_pem = <<-EOT
    -----BEGIN CERTIFICATE-----
    REPLACE_WITH_THE_BROKER_CA
    -----END CERTIFICATE-----
  EOT
}

producer = {
  dynamicProducer = false
  static = [
    {
      name       = "acks"
      queue      = "PAYMENTS.ACK"
      persistent = true
      properties = { msgType = "ack", source = "firefly" }
    },
    {
      name          = "audit"
      queue         = "PAYMENTS.AUDIT"
      messageFormat = "envelope"
      timeToLive    = 86400000
      properties    = { schema = "kld-event-v1" }
    },
  ]
}
