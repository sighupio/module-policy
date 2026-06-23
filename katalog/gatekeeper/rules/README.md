# Gatekeeper Rules

<!-- <SD-DOCS> -->

## Overview

A policy is a group of rules that enforce a desired behavior. This package provides a set of common policies out of the box to get started in securing your cluster. A policy in Gatekeeper is defined by two objects: a `ConstraintTemplate`, which defines the common logic of the policy, and a `Constraint`, which instantiates that logic with the right values for the required parameters.

All the `Constraints` exclude the SD "infra" namespaces (`kube-system`, `logging`, `monitoring`, `ingress-nginx`, `cert-manager`) by default to avoid service disruption.

The following constraint templates ship with SIGHUP Distribution:

| Rule Name                  | Description                                                                                                                                            |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `k8slivenessprobe`         | Deny pods that don't declare `livenessProbe`.                                                                                                          |
| `k8sreadinessprobe`        | Deny pods that don't declare `readinessProbe`.                                                                                                         |
| `k8suniqueingresshost`     | Deny duplicated ingress across the cluster.                                                                                                            |
| `k8suniqueserviceselector` | Deny duplicated services selector in the same namespace.                                                                                              |
| `securitycontrols`         | Deny container images with the `latest` tag, with no limits declared (both CPU and memory), with privilege escalation capability and root containers. |

## Upstream project

This package is based on the upstream [Gatekeeper][gatekeeper-github] and on the SIGHUP base constraint library.

## Deployment

This package is deployed as part of **Policy Module** when you create a cluster with `furyctl` and `spec.distribution.modules.policy.type` is set to `gatekeeper`.

You can control whether the default policies are installed and customize enforcement under `spec.distribution.modules.policy.gatekeeper` in your `furyctl.yaml`. See the [module documentation](../../../README.md) and the configuration reference ([EKSCluster][schema-reference-eks], [KFDDistribution][schema-reference-kfd], [OnPremises][schema-reference-onprem]) for the available options.

<!-- Links -->

[gatekeeper-github]: https://github.com/open-policy-agent/gatekeeper
[schema-reference-eks]: https://docs.sighup.io/docs/reference/ekscluster#specdistributionmodulespolicy
[schema-reference-kfd]: https://docs.sighup.io/docs/reference/kfddistribution#specdistributionmodulespolicy
[schema-reference-onprem]: https://docs.sighup.io/docs/reference/onpremises#specdistributionmodulespolicy

<!-- </SD-DOCS> -->

## License

For license details please see [LICENSE](../../../LICENSE)
