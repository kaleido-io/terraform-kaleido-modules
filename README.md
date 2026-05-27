## Kaleido Terraform Modules

This repository contains the Kaleido Terraform modules for the Kaleido Enterprise Platform, using the official [Terraform provider for Kaleido](https://github.com/kaleido-io/terraform-provider-kaleido).

See [modules](./modules) for the available modules, and [examples](./examples) for specific examples using one or more modules for different use cases.

### Usage

```hcl
terraform {
  required_providers {
    kaleido = {
      source = "kaleido-io/kaleido"
      version = ">=1.3.0"
    }
  }
}

module "example" {
  source = "git@github.com:kaleido-io/terraform-kaleido-modules.git//modules/example?ref=main"
  # ... module inputs ...
}
```
