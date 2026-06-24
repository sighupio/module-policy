# Gatekeeper

<!-- <SD-DOCS> -->

## Overview

Gatekeeper is a Kubernetes-native policy engine, built on top of the Open Policy Agent (OPA), that runs as a Validating Admission Webhook to enforce policies (constraints) at runtime. In the Policy Module it is one of the two selectable policy engines and ships with a set of SIGHUP base constraints, a monitoring integration and the Gatekeeper Policy Manager web UI.

This directory groups the Gatekeeper packages:

- [`core`](core) — the Gatekeeper deployment, ready to enforce rules.
- [`rules`](rules) — the SIGHUP base set of `ConstraintTemplates` and `Constraints`.
- [`monitoring`](monitoring) — `ServiceMonitor`, Prometheus rules and Grafana dashboard.
- [`gpm`](gpm) — Gatekeeper Policy Manager, a read-only web UI for Gatekeeper.

## Upstream project

This package is based on the upstream [Gatekeeper][gatekeeper-github].

## Deployment

This package is deployed as part of **Policy Module** when you create a cluster with `furyctl` and `spec.distribution.modules.policy.type` is set to `gatekeeper`.

You can customize it under `spec.distribution.modules.policy.gatekeeper` in your `furyctl.yaml`. See the [module documentation](../../README.md) and the configuration reference ([EKSCluster][schema-reference-eks], [KFDDistribution][schema-reference-kfd], [OnPremises][schema-reference-onprem]) for the available options.

<!-- Links -->

[gatekeeper-github]: https://github.com/open-policy-agent/gatekeeper
[schema-reference-eks]: https://docs.sighup.io/docs/reference/ekscluster#specdistributionmodulespolicy
[schema-reference-kfd]: https://docs.sighup.io/docs/reference/kfddistribution#specdistributionmodulespolicy
[schema-reference-onprem]: https://docs.sighup.io/docs/reference/onpremises#specdistributionmodulespolicy

<!-- </SD-DOCS> -->

## License

For license details please see [LICENSE](../../LICENSE)
