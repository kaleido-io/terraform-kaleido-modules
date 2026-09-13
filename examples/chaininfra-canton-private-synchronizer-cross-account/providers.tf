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
  alias = "account_1"
  platform_api = var.kaleido_platform_api_account_1
  platform_username = var.kaleido_platform_username_account_1
  platform_password = var.kaleido_platform_password_account_1
}

provider "kaleido" {
  alias = "account_2"
  platform_api = var.kaleido_platform_api_account_2
  platform_username = var.kaleido_platform_username_account_2
  platform_password = var.kaleido_platform_password_account_2
}