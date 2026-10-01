variable "environment_id" {
  type        = string
  description = "ID of the environment to deploy the EVM connector into."
}

variable "stack_name" {
  type        = string
  default     = "evm"
  description = "Name of the EVMConnectorStack."
}

variable "runtime_size" {
  type        = string
  default     = "Small"
  description = "Size of the EVMConnectorRuntime."
}

variable "runtime_zone" {
  type        = string
  default     = null
  description = "Zone of the EVMConnectorRuntime."
}

variable "connector_name" {
  type        = string
  default     = "evm-connector"
  description = "Name of the EVMConnector runtime and service."
}

variable "key_manager_service_id" {
  type        = string
  description = "ID of the KeyManager service used to sign EVM transactions."
}

variable "database_name" {
  type        = string
  default     = null
  description = "Optional external database name for the EVMConnector service. Required only on platform instances configured for externally-provisioned databases; omit for managed-database instances."
}

variable "flow_versions" {
  type        = map(string)
  default     = {}
  description = "Template version of each connector flow, keyed by flow name (submission, query). A version (e.g. \"2026.09.0\") pins the flow there; \"latest\" upgrades it whenever the connector service stores a newer version. A flow left out is deployed at the latest version and then held there until it is pinned or set to latest. Versions only move forward."
  validation {
    condition     = alltrue([for f in keys(var.flow_versions) : contains(local.connector_flows, f)])
    error_message = "flow_versions keys must be connector flow names: ${join(", ", local.connector_flows)}."
  }
  validation {
    condition     = alltrue([for v in values(var.flow_versions) : v == "latest" || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", v))])
    error_message = "Each flow_versions value must be \"latest\" or a version such as \"2026.09.0\"."
  }
}

variable "deploy_utilities_api" {
  type        = bool
  default     = false
  description = "Deploy the EVM utilities standard API, which provides synchronous operations such as looking up any transaction by hash."
}

# ─── Service-level config ─────────────────────────────────────────────────────

variable "evm_gateway_service_id" {
  type        = string
  default     = null
  description = "Optional EVMGateway service ID for Kaleido-managed Besu networks."
}

variable "jsonrpc_url" {
  type        = string
  default     = null
  description = "Optional external JSON-RPC URL (for public networks)."
}

variable "jsonrpc_auth" {
  type = object({
    username = string
    password = string
  })
  default     = null
  sensitive   = true
  description = "Optional basic-auth credentials for the JSON-RPC endpoint. When set, the module registers them as a credSet named 'rpc_auth' on the EVMConnector service and references it from the service config (auth.credSetRef = \"rpc_auth\"). The upstream config schema does not allow username/password inlined under auth."
}

variable "ecosystem" {
  type = object({
    name        = string
    displayName = optional(string)
  })
  default     = null
  description = "Ecosystem metadata block (e.g. { name = \"ethereum\", displayName = \"Ethereum\" })."
}

variable "network" {
  type = object({
    name        = string
    displayName = optional(string)
    chainId     = optional(string)
  })
  default     = null
  description = "Network metadata block (e.g. { name = \"ethereum-mainnet\", chainId = \"1\" })."
}

# ─── Config profile values (one variable per upstream config type) ────────────
# Schemas mirror <upstream connector definitions source>/evm/config_types/*.yaml.
#
# Each variable is the value of the connector's default profile for that config type. Left null, the
# profile takes the chain's default from the platform catalog, when the catalog has one for the
# ecosystem and network, and otherwise the connector's own defaults. A value that is set is deep
# merged into the chain's default, so only the settings given change.

variable "track_chain_defaults" {
  type        = bool
  default     = false
  description = "Follow the platform catalog's chain defaults as they change. By default the defaults are read once, when the connector is first deployed (or its ecosystem or network changes), and held; a check warns when the catalog has since changed."
}

variable "confirmations" {
  # No defaults inside the object: a value the caller leaves out is left to the connector, rather
  # than pinned here. Pinning count to 0 made a connector on a public chain wait for no
  # confirmations at all.
  type = object({
    count = optional(number)
    resubmission = optional(object({
      enabled = optional(bool)
      timeout = optional(string)
    }))
  })
  default     = null
  description = "evm.confirmations — number of confirmations before a transaction is considered final, plus optional resubmission policy. Omit to use the chain's default from the platform catalog (for example 12 on Ethereum mainnet), or the connector's where the catalog has none."
}

variable "gas_estimation" {
  type = object({
    scaleFactor = optional(number, 1.0)
  })
  default     = null
  description = "evm.gasEstimation"
}

variable "gas_pricing" {
  type = object({
    format = optional(object({
      name                 = optional(string)
      enableLegacyFallback = optional(bool)
    }))
    # `source` is a tagged union — set exactly one of fixedGasPrice / gasOracleAPI / rpcEndpoint.
    source = optional(object({
      fixedGasPrice = optional(object({
        enabled              = optional(bool)
        maxFeePerGas         = optional(string)
        maxPriorityFeePerGas = optional(string)
        gasPrice             = optional(string)
      }))
      gasOracleAPI = optional(object({
        enabled                   = optional(bool)
        enableRPCEndpointFallback = optional(bool)
        url                       = optional(string)
        method                    = optional(string)
        body                      = optional(string)
        bodyEncoding              = optional(string)
        httpHeaders               = optional(map(string))
        responseTemplate = optional(object({
          jsonata = optional(string)
        }))
        cache = optional(object({
          enabled = optional(bool)
          size    = optional(string)
          ttl     = optional(string)
        }))
      }))
      rpcEndpoint = optional(object({
        cache = optional(object({
          enabled = optional(bool)
          size    = optional(string)
          ttl     = optional(string)
        }))
        ethFeeHistory = optional(object({
          baseFeeBufferFactor   = optional(number)
          historyBlockCount     = optional(number)
          priorityFeePercentile = optional(number)
        }))
      }))
    }))
    autoIncrement = optional(object({
      enabled              = optional(bool)
      maxFeePerGas         = optional(object({ multiplier = optional(number) }))
      maxPriorityFeePerGas = optional(object({ multiplier = optional(number) }))
      gasPrice             = optional(object({ multiplier = optional(number) }))
    }))
    # Caps are strings in the smallest denomination (wei), as values can exceed a number's precision.
    caps = optional(object({
      enabled              = optional(bool)
      maxFeePerGas         = optional(string)
      maxPriorityFeePerGas = optional(string)
      gasPrice             = optional(string)
    }))
  })
  default     = null
  description = "evm.gasPricing — format (eip1559|legacy), source (tagged union: fixedGasPrice | gasOracleAPI | rpcEndpoint), auto-increment, and caps."
}

variable "nonce_assignment" {
  type = object({
    previousTxnsCondition = optional(string)
  })
  default     = null
  description = "evm.nonceAssignment"
}

variable "submission" {
  type = object({
    # Keys are submission-error categories (gas_limit_error, gas_price_error, signature_error, …)
    # — the schema is open, so users may add their own categories.
    errorTypeMatchers = optional(map(object({
      containsIgnoreCase = optional(list(string))
      minInterval        = optional(string)
    })))
  })
  default     = null
  description = "evm.submission — error-type matchers keyed by submission error category."
}

variable "transaction_serialization" {
  type = object({
    format = optional(string)
  })
  default     = null
  description = "evm.transactionSerialization — format is auto (derive from the gas price fields, the default) or original (pre-EIP-155 legacy, without the chain ID in the signed payload)."
  validation {
    condition     = contains(["auto", "original"], coalesce(try(var.transaction_serialization.format, null), "auto"))
    error_message = "transaction_serialization.format must be auto or original."
  }
}

variable "prioritization" {
  type = object({
    # fifo (arrival order, the default) or tiered.
    type = optional(string)
    tiered = optional(object({
      priorityLabel   = optional(string)
      defaultPriority = optional(string)
      defaultDelay    = optional(string)
      # Ordered highest first: earlier tiers receive lower nonces.
      tiers = optional(list(object({
        labelValue = optional(string)
        delay      = optional(string)
      })))
    }))
  })
  default     = null
  description = "evm.prioritization — the order in which transactions are assigned nonces: fifo, or tiered by the value of a transaction label. It is an optional config type of the submission flow: the type is always deployed, but a profile is created and bound only when this is set. Omitted, nonces are assigned in arrival order."
  validation {
    condition     = contains(["fifo", "tiered"], coalesce(try(var.prioritization.type, null), "fifo"))
    error_message = "prioritization.type must be fifo or tiered."
  }
  # The submission flow's prioritization slot was added in 2026.09.0; an earlier version cannot bind it.
  validation {
    condition     = var.prioritization == null || coalesce(local.submission_pin, 202600090000) >= 202600090000
    error_message = "prioritization needs the submission flow at version 2026.09.0 or later; flow_versions pins it earlier."
  }
}

variable "block_events" {
  type = object({
    minWait = optional(string, "500ms")
    maxWait = optional(string, "5s")
  })
  default     = null
  description = "evm.blockEventsConfig — debounce timings for the latest-block poller."
}

variable "transaction_events" {
  # ABI fields (`abi`, `logFilters[].events`) accept native Terraform lists of objects;
  # the upstream JSON Schema is recursive (parameters have `components` of the same shape)
  # so we type them as `any` rather than re-encode the recursion.
  type = object({
    abi                              = optional(any)
    batchSize                        = optional(number)
    batchTimeout                     = optional(string)
    catchupBlockFetchAhead           = optional(number)
    catchupPageSize                  = optional(number)
    catchupPageSizeAdaptiveAlpha     = optional(number)
    catchupPageSizeAdaptiveMax       = optional(number)
    catchupPageSizeAdaptiveMin       = optional(number)
    catchupRetryMaxAttempts          = optional(number)
    catchupRetryRangeReductionFactor = optional(number)
    decodeConstructors               = optional(bool)
    enableBlockTrace                 = optional(bool)
    eventMode                        = optional(string)
    fromBlock                        = optional(string)
    includeBinaryInput               = optional(bool)
    includeBinaryLogs                = optional(bool)
    includeInputs                    = optional(bool)
    includeLogsBloom                 = optional(bool)
    logFilters = optional(list(object({
      addresses       = optional(list(string))
      eventSignatures = optional(list(string))
      events          = optional(any)
      topic0          = optional(list(string))
      topic1          = optional(list(string))
      topic2          = optional(list(string))
      topic3          = optional(list(string))
    })))
    omitSolidityDef = optional(bool)
    outputFormat    = optional(string)
    pollTimeout     = optional(string)
    requiredConfirmations = optional(number)
    traceFilters = optional(list(object({
      addresses   = optional(list(string))
      excludeFrom = optional(bool)
      excludeTo   = optional(bool)
    })))
    unfiltered = optional(bool)
  })
  default     = null
  description = "evm.transactionEventsConfig — block-walking event stream tuning. eventMode is one of all|require_decoded|filter_decoded."
}

variable "contract_event_listener" {
  type = object({
    fromBlock    = optional(string)
    batchSize    = optional(number)
    batchTimeout = optional(string)
    pollTimeout  = optional(string)
    filters = optional(list(object({
      address = optional(string)
      # ABI event definition. Recursive schema — accept Terraform native objects.
      event = optional(any)
    })))
  })
  default     = null
  description = "evm.contractEventListener — block-walking listener bound to a contract address + event ABI."
}
