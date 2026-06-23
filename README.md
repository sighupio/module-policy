<!-- markdownlint-disable MD033 -->
<h1 align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/sighupio/distribution/refs/heads/main/docs/assets/white-logo.png">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/sighupio/distribution/refs/heads/main/docs/assets/black-logo.png">
  <img alt="Shows a black logo in light color mode and a white one in dark color mode." src="https://raw.githubusercontent.com/sighupio/distribution/refs/heads/main/docs/assets/white-logo.png">
</picture><br/>
  Policy Module
</h1>
<!-- markdownlint-enable MD033 -->

![Release](https://img.shields.io/badge/Latest%20Release-v1.17.0-blue)
![License](https://img.shields.io/github/license/sighupio/module-policy?label=License)
![Slack](https://img.shields.io/badge/slack-@kubernetes/fury-yellow.svg?logo=slack&label=Slack)

<!-- <SD-DOCS> -->

**Policy Module** provides runtime policy enforcement for [SIGHUP Distribution (SD)][kfd-repo].

If you are new to SD please refer to the [official documentation][kfd-docs] on how to get started with SD.

## Overview

> [!TIP]
> [Starting from Kubernetes v1.25][kubernetes-pss-stable], [Pod Security Standards (PSS)][kubernetes-pss] are promoted to stable. For most use cases, the policies defined in the Pod Security Standards are a great starting point; consider applying them before switching to one of the tools provided by this module.
>
> For more advanced use cases, where custom policies that are not included in the PSS must be enforced, this module is the right choice.

The Kubernetes API server provides a mechanism to review every request that is made (object creation, modification or deletion) through a [Validating Admission Webhook][kubernetes-vaw-docs] that validates each request and tells the API server whether it is allowed based on some logic (policy).

**Policy Module** is based on [Gatekeeper][gatekeeper-page] and [Kyverno][kyverno-page], two popular open-source Kubernetes-native policy engines that run as Validating Admission Webhooks. It allows writing custom constraints (policies) and enforcing them at runtime. [SIGHUP][sighup-page] provides a set of base constraints that can be used both as a starting point and as a reference for implementing new rules matching your requirements.

## Packages

The following packages are included in Policy Module:

| Package                                                | Version   | Description                                                                                                                                              |
| ------------------------------------------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Gatekeeper Core](katalog/gatekeeper/core)             | `v3.22.2` | Gatekeeper deployment, ready to enforce rules.                                                                                                          |
| [Gatekeeper Rules](katalog/gatekeeper/rules)           | `N.A.`    | A set of custom rules to get started with policy enforcement.                                                                                           |
| [Gatekeeper Monitoring](katalog/gatekeeper/monitoring) | `N.A.`    | Metrics, alerts and dashboard for monitoring Gatekeeper.                                                                                                |
| [Gatekeeper Policy Manager](katalog/gatekeeper/gpm)    | `v1.1.1`  | Gatekeeper Policy Manager, a simple to use web UI for Gatekeeper.                                                                                       |
| [Kyverno](katalog/kyverno)                             | `v1.18.1` | Kyverno is a policy engine designed for Kubernetes. It can validate, mutate and generate configurations using admission controls and background scans.  |

Click on each package to see its full documentation.

## Compatibility

| Kubernetes Version |   Compatibility    | Notes           |
| ------------------ | :----------------: | --------------- |
| `1.33.x`           | :white_check_mark: | No known issues |
| `1.34.x`           | :white_check_mark: | No known issues |
| `1.35.x`           | :white_check_mark: | No known issues |

Check the [compatibility matrix][compatibility-matrix] for additional information about previous releases of the module.

## Usage

**Policy Module** is part of SIGHUP Distribution (SD) and is deployed automatically by [`furyctl`][furyctl-repo] when you create or update a cluster. You don't need to download, vendor or install its packages manually.

### Configuration

You configure the module under `spec.distribution.modules.policy` in your `furyctl.yaml`. The `type` field selects the policy engine to deploy: `gatekeeper`, `kyverno`, or `none` to disable the module. The other fields are optional and fall back to sensible defaults.

```yaml
apiVersion: kfd.sighup.io/v1alpha2
kind: KFDDistribution
spec:
  distribution:
    modules:
      policy:
        # Select the policy engine: none, gatekeeper or kyverno
        type: gatekeeper
        gatekeeper:
          enforcementAction: deny
          installDefaultPolicies: true
          additionalExcludedNamespaces: []
```

To use Kyverno instead of Gatekeeper, set `type: kyverno` and configure the `kyverno` block:

```yaml
apiVersion: kfd.sighup.io/v1alpha2
kind: KFDDistribution
spec:
  distribution:
    modules:
      policy:
        type: kyverno
        kyverno:
          validationFailureAction: Enforce
          installDefaultPolicies: true
          additionalExcludedNamespaces: []
```

See the configuration reference for your cluster kind for the full list of available options: [EKSCluster][schema-reference-eks], [KFDDistribution][schema-reference-kfd] or [OnPremises][schema-reference-onprem].

To install SD from scratch, follow the [Getting started][getting-started] guide.

<!-- Links -->

[kubernetes-pss-stable]: https://kubernetes.io/blog/2022/08/25/pod-security-admission-stable/
[kubernetes-pss]: https://kubernetes.io/docs/concepts/security/pod-security-standards/
[kubernetes-vaw-docs]: https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/
[gatekeeper-page]: https://github.com/open-policy-agent/gatekeeper
[kyverno-page]: https://github.com/kyverno/kyverno
[sighup-page]: https://sighup.io
[kfd-repo]: https://github.com/sighupio/distribution
[furyctl-repo]: https://github.com/sighupio/furyctl
[kfd-docs]: https://docs.sighup.io/docs/distribution/
[schema-reference-eks]: https://docs.sighup.io/docs/reference/ekscluster#specdistributionmodulespolicy
[schema-reference-kfd]: https://docs.sighup.io/docs/reference/kfddistribution#specdistributionmodulespolicy
[schema-reference-onprem]: https://docs.sighup.io/docs/reference/onpremises#specdistributionmodulespolicy
[getting-started]: https://docs.sighup.io/docs/getting-started/
[compatibility-matrix]: https://github.com/sighupio/module-policy/blob/main/docs/COMPATIBILITY_MATRIX.md

<!-- </SD-DOCS> -->

<!-- <FOOTER> -->

## Contributing

Before contributing, please read first the [Contributing Guidelines](https://github.com/sighupio/distribution/blob/main/docs/CONTRIBUTING.md).

### Reporting Issues

In case you experience any problem with the module, please [open a new issue](https://github.com/sighupio/module-policy/issues/new/choose).

## License

This module is open-source and it's released under the following [LICENSE](LICENSE).

<!-- </FOOTER> -->
