## Testing

All modules are tested continuously in a private CI pipeline using the `main` branch of the
[terraform-provider-kaleido](https://github.com/kaleido-io/terraform-provider-kaleido) repository,
and our internal testing infrastructure of the Kaleido Enterprise Platform. Modules are tested via
the `examples` in this repository.

Contributors must have access to the Kaleido Enterprise Platform, and are expected to test their changes and contributions
against their own accounts. Include the version of the platform you tested against according to your account settings page.

For a release of the Terraform provider, it is tested against the latest Kaleido Enterprise Platform release, and the latest release of the Terraform modules
to ensure backwards compatibility. For a release of the Terraform modules, it is tested against the latest Kaleido Enterprise Platform release, and the latest release of the Terraform provider
to ensure forwards compatibility. As a result, the Terraform provider and modules are tested in lock-step against each other relative to Kaleido Enterprise Platform releases.
