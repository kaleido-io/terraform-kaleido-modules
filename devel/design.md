## Design

This document serves as a concise our architectural decision record for the Kaleido Terraform modules.

### Principles

1. Modules must be self-contained and reusable - representing an individual `kaleido_platform_service`, `kaleido_platform_network`, or `kaleido_platform_stack`.
2. Modules must provide strongly variable inputs and outputs - serving as documentation for loosely typed resources like `kaleido_platform_service` and `kaleido_platform_network`.
3. Modules cannot import other modules.
4. Every module must be used in at least one example.
5. Modules must enforce a minimum version of the Kaleido Terraform provider.
6. Modules should avoid `count` (conditional) and `for_each` (loops).
