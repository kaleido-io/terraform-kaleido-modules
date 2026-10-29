terraform {
  required_version = ">= 1.11.0" // OpenTofu and/or Terraform
  required_providers {
    kaleido = {
      source  = "kaleido-io/kaleido"
      version = "~> 1.3.0"
    }
  }
}
