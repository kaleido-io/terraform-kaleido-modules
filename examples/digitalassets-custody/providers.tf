terraform {
  required_version = ">= 1.11.0" // OpenTofu and/or Terraform
  required_providers {
    kaleido = {
      source = "kaleido-io/kaleido"
      version = "~> 1.3.0"
    }
  }
}

provider "kaleido" {
  platform_api = var.kaleido_platform_api
  platform_username = var.kaleido_platform_username != "" ? var.kaleido_platform_username : null
  platform_password = var.kaleido_platform_password != "" ? var.kaleido_platform_password : null
  platform_bearer_token = var.kaleido_platform_bearer_token != "" ? var.kaleido_platform_bearer_token : null
}