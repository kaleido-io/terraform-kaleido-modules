## Summary

Create an environment with:

* Besu Chain Infrastructure Stack
    - Besu Network
    - 1 Besu Node (validator)
    - EVM Gateway
    - Block indexer
* Key Manager
    - HD wallet backing the Paladin node keys (KMS folder per node)
    - Domain deployer key for the domain factory contracts
* Contract Manager
* Workflow Engine (required by the EVM Connector)
* EVM Connector (web3 middleware) 
* Paladin Domains 
    - Noto
    - Pente
* Chain Infrastructure Stack - Paladin
    - Paladin Network with an EVM registry
    - Configurable number of Paladin nodes, named `<prefix>-1` ... `<prefix>-N`. By
      convention node 1 deploys the registry.
