terraform {
  required_version = ">= 1.11.0" // OpenTofu and/or Terraform
  required_providers {
    kaleido = {
      source = "kaleido-io/kaleido"
      // 1.3.5 added the artifact registry resources and registry file references
      version = "~> 1.3, >= 1.3.5"
    }
  }
}
