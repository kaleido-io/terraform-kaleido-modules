## Summary

Create an environment with:

* Besu Chain Infrastructure Stack
    - Besu Network
    - 1 Besu Node (signer)
    - EVM Gateway
* Key Manager
    - HD wallet backing the Paladin node keys (1 KMS folder per node)
    - Domain deployer key for the domain factory contracts
* Contract Manager
* Transaction Manager
* Paladin Domains (deployed via the Contract Manager)
    - Noto
    - Pente
* Chain Infrastructure Stack - Paladin
    - Paladin Network with an EVM registry
    - 1 "admin" node that deploys the registry
    - Configurable amount of "joiner" nodes
