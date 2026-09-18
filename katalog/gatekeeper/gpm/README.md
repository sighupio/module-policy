# Gatekeeper Policy Manager (GPM)

<!-- <SD-DOCS> -->

## Overview

Gatekeeper Policy Manager (GPM) is a simple, read-only web UI for viewing the status of OPA Gatekeeper policies in a Kubernetes cluster. It can display all the defined `ConstraintTemplates` with their rego code, the Gatekeeper configuration CRDs, and all the `Constraints` with their current status, violations, enforcement action and match definitions. It also shows Gatekeeper's mutation resources, the related Kubernetes events, and a Resources view that groups audit violations by namespace and object.

GPM is currently deployed without authentication in this module: it uses its own `ServiceAccount` for in-cluster access and does not enable OIDC or JWT. Expose it accordingly.

## Upstream project

This package is based on the upstream [Gatekeeper Policy Manager][gpm-github].

## Deployment

This package is deployed as part of **Policy Module** when you create a cluster with `furyctl` and `spec.distribution.modules.policy.type` is set to `gatekeeper`. See the [module documentation](../../../README.md) to learn how the Policy Module is installed and configured.

<!-- Links -->

[gpm-github]: https://github.com/sighupio/gatekeeper-policy-manager

<!-- </SD-DOCS> -->

## License

For license details please see [LICENSE](../../../LICENSE)
