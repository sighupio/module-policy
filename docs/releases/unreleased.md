# Policy Core Module Release vX.Y.Z

Welcome to the latest release of `Policy` module of [SIGHUP Distribution](https://github.com/sighupio/distribution) maintained by team SIGHUP by ReeVo.

## Component Images 🚢

| Component                   | Supported Version                                                                     | Previous Version |
| --------------------------- | ------------------------------------------------------------------------------------- | ---------------- |
| `gatekeeper`                | [`v3.23.1`](https://github.com/open-policy-agent/gatekeeper/releases/tag/v3.23.1)     | `v3.23.1`        |
| `gatekeeper-policy-manager` | [`v1.1.1`](https://github.com/sighupio/gatekeeper-policy-manager/releases/tag/v1.1.1) | `No Update`      |
| `kyverno`                   | [`v1.19.1`](https://github.com/kyverno/kyverno/releases/tag/v1.19.1)                  | `v1.19.1`        |

> Please refer the individual release notes to get a detailed information on each release.

## Compatibility

This release maintains compatibility with Kubernetes versions 1.33.x through 1.36.x.

## Update Guide 🦮

### Process

#### Gatekeeper

To upgrade this package, you need to download this new version, then apply the `kustomize` project. No further action is required.

```bash
kustomize build katalog/gatekeeper | kubectl apply -f -
```

#### Kyverno

To upgrade this package, you need to download this new version, then apply the `kustomize` project. No further action is required.

```bash
kustomize build katalog/kyverno | kubectl apply -f -
```
