# Policy Core Module Release vx.x.x

Welcome to the latest release of `Policy` module of [SIGHUP Distribution](https://github.com/sighupio/distribution) maintained by team SIGHUP by ReeVo.

This is a minor release including the following changes:

- Add support for Kubernetes 1.33
- Update Kyverno to version 1.15.1

## Component Images 🚢

| Component                   | Supported Version                                                                       | Previous Version |
| --------------------------- | --------------------------------------------------------------------------------------- | ---------------- |
| `gatekeeper`                | [`v3.18.2`](https://github.com/open-policy-agent/gatekeeper/releases/tag/v3.18.2)       | `No update`        |
| `gatekeeper-policy-manager` | [`v1.0.13`](https://github.com/sighupio/gatekeeper-policy-manager/releases/tag/v1.0.13) | `No update`      |
| `kyverno`                   | [`v1.15.1`](https://github.com/kyverno/kyverno/releases/tag/v1.15.1)                    | `v1.12.6`        |

> Please refer the individual release notes to get a detailed information on each release.

## Update Guide 🦮

### Process

#### Gatekeeper

To upgrade this package from `v1.14.0` to `vx.x.x`, you need to download this new version, then apply the `kustomize` project. No further action is required.

```bash
kustomize build katalog/gatekeeper | kubectl apply -f -
```
#### Kyverno

To upgrade this package from `v1.14.0` to `vx.x.x`, you need to download this new version, then apply the `kustomize` project. No further action is required.
```bash
kustomize build katalog/kyverno | kubectl apply -f -
```