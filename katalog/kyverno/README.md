# Kyverno

<!-- <SD-DOCS> -->

## Overview

Kyverno is a policy engine designed for Kubernetes. It can validate, mutate and generate configurations using admission controls and background scans. Kyverno policies are Kubernetes resources and do not require learning a new language. In the Policy Module it is one of the two selectable policy engines, deployed in HA mode and excluding the SD `infra` namespaces from its webhooks by default.

This package ships a set of predefined policies that form the SD baseline, similar to what is provided with the Gatekeeper package:

| Policy                         | Description                                                                                                                                  |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| disallow-capabilities-strict   | Adding capabilities other than `NET_BIND_SERVICE` is disallowed; all containers must explicitly drop `ALL` capabilities.                    |
| disallow-capabilities          | Adding capabilities beyond those listed in the policy is disallowed.                                                                         |
| disallow-host-namespaces       | Pods should not be allowed access to host namespaces (PID, IPC, network).                                                                   |
| disallow-host-path             | Ensures no `hostPath` volumes are in use.                                                                                                    |
| disallow-host-ports            | Ensures the `hostPort` field is unset or set to `0`.                                                                                        |
| disallow-latest-tag            | Validates that images specify a tag and that it is not `latest`.                                                                            |
| disallow-privilege-escalation  | Ensures the `allowPrivilegeEscalation` field is set to `false`.                                                                             |
| disallow-privileged-containers | Ensures Pods do not run in privileged mode.                                                                                                  |
| disallow-proc-mount            | Ensures nothing but the default `procMount` can be specified.                                                                               |
| require-pod-probes             | Liveness and readiness probes must be configured.                                                                                           |
| require-run-as-nonroot         | Ensures `runAsNonRoot` is set to `true`.                                                                                                    |
| restrict-sysctls               | Disallows sysctls except for an allowed "safe" subset.                                                                                       |
| unique-ingress-host-and-path   | Ensures Ingresses are globally unique with respect to the host plus path combination.                                                       |

## Upstream project

This package is based on the upstream [Kyverno][kyverno-github].

## Deployment

This package is deployed as part of **Policy Module** when you create a cluster with `furyctl` and `spec.distribution.modules.policy.type` is set to `kyverno`.

You can control whether the default policies are installed and customize enforcement under `spec.distribution.modules.policy.kyverno` in your `furyctl.yaml`. See the [module documentation](../../README.md) and the configuration reference ([EKSCluster][schema-reference-eks], [KFDDistribution][schema-reference-kfd], [OnPremises][schema-reference-onprem]) for the available options.

<!-- Links -->

[kyverno-github]: https://github.com/kyverno/kyverno
[schema-reference-eks]: https://docs.sighup.io/docs/reference/ekscluster#specdistributionmodulespolicy
[schema-reference-kfd]: https://docs.sighup.io/docs/reference/kfddistribution#specdistributionmodulespolicy
[schema-reference-onprem]: https://docs.sighup.io/docs/reference/onpremises#specdistributionmodulespolicy

<!-- </SD-DOCS> -->

## License

For license details please see [LICENSE](../../LICENSE)
