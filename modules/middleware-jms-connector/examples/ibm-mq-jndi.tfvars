# JMS connector to IBM MQ through a file-system JNDI naming service: the messaging administrators
# exported the connection factory and queues with JMSAdmin to a .bindings file. Queue and topic names
# in streams and workflows are then JNDI names (lookupDestinations). The IBM MQ client and the
# fscontext provider that reads .bindings files are uploaded from local files, tagged by version and
# checksum. The platform sets providerUrl to the .bindings file's directory.

connector_name      = "ibm-mq-connector"
registry_service_id = "s:REPLACE_WITH_ARTIFACT_REGISTRY_SERVICE_ID"

client_jars = [
  { name = "ibm/com.ibm.mq.jakarta.client-9.4.3.0.jar", file_path = "jars/com.ibm.mq.jakarta.client-9.4.3.0.jar", version = "9.4.3.0" },
  # com.sun.messaging.mq:fscontext, the JNDI provider that reads .bindings files
  { name = "ibm/fscontext-4.6-b01.jar", file_path = "jars/fscontext-4.6-b01.jar", version = "4.6-b01" },
]

connection_factory = {
  jndi = {
    initialContextFactory = "com.sun.jndi.fscontext.RefFSContextFactory"
    connectionFactoryName = "PaymentsCF"
    lookupDestinations    = true
  }
}

jndi_bindings_file = "jndi/.bindings"

broker_auth = {
  username = "app"
  password = "change-me"
}
