## Modules

This directory contains the Kaleido Terraform modules for the Kaleido Enterprise Platform. They are versioned altogether within a single release of the modules monorepo,
tested against the latest Kaleido Enterprise Platform release, and the latest release of the Terraform provider at a minimum. Breaking changes will be documented in the CHANGELOG
if ever necessary, but will be avoided if possible in preference to creating a new module.

> **NOTE**: Importing existing resources into the Terraform state for modules is not currently supported, as the Terraform provider does not yet support importing resources into modules.
