# AGENTS

Guidance for AI agents working in this repo.

## Repo

Reusable Terraform modules for the Kaleido Enterprise Platform, built on the
[terraform-provider-kaleido](https://github.com/kaleido-io/terraform-provider-kaleido).
- `modules/` — one module per `kaleido_platform_service` / `_network` / `_stack`.
- `examples/` — runnable compositions; every module must appear in at least one.
- `devel/` — `design.md` (principles) and `testing.md` (CI contract). Read both before non-trivial changes.

## Module rules

See [`devel/design.md`](./devel/design.md).

## Local development

The provider is iterated in lockstep with modules. To test against unreleased provider changes, check out
`../terraform-provider-kaleido`, `make build`, and point a `~/.terraformrc` `dev_overrides` block at the
built binary (both `kaleido-io/kaleido` and `registry.terraform.io/kaleido-io/kaleido` addresses) — see
`.github/workflows/ci.yml` for the exact incantation CI uses.

## CI

`.github/workflows/ci.yml` builds the provider from `main`, sets a dev override, and runs `tflint --recursive`
over each subdirectory of `modules/` and `examples/`. Keep both lintable.

## Conventions

- Match existing `variables.tf` style: typed objects with `optional(...)` fields, descriptions that name the upstream
  config type (e.g. `evm.gasPricing`), and sensible defaults.
- Mark credential variables `sensitive = true`.
- Example `tfvars` live under `modules/<name>/examples/` and document per-network defaults.
- Don't add new top-level files (READMEs, plans) unless asked.
