# Kyverno - maintenance

To maintain the Kyverno package, you should follow this steps.

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/

helm repo update

helm search repo kyverno/kyverno # get the latest chart version
helm pull kyverno/kyverno --version 3.9.1  --untar --untardir /tmp
```

> Note: if the templating gives some error, change `kubeVersion:`  on the /tmp/kyverno/Chart.yaml.

```bash
helm template kyverno /tmp/kyverno --values MAINTENANCE.values.yaml --namespace kyverno > built-kyverno.yaml
helm template kyverno /tmp/kyverno --values MAINTENANCE.values.yaml --set crds.install=true --namespace kyverno | yq 'select(.kind == "CustomResourceDefinition")' > crds.yaml
```

1. Compare the core/deploy.yaml file with the built-kyverno.yaml to find differences with the current version.

2. Overwrite the content of the generated from chart crds.yaml with the content of the katalog/kyverno/core/crds.yaml file.

3. Sync the new image to our registry by updating the [OPA images.yaml file container-image-sync repository](https://github.com/sighupio/container-image-sync/blob/main/modules/opa/images.yml).

4. Update the `kustomization.yaml` file with the new version in the image tag.

What was changed:
- Removed all the helm hooks from the deploy
- Manually added policies to have a similar ruleset as gatekeeper
- Whitelisted all the `infra` fury namespaces in the `MAINTENANCE.values.yaml` variable file
- Keep the Validating Admission Policy set to false

## Testing the policies

`katalog/tests/kyverno.sh` covers every policy in `policies/collection/`, on each supported Kubernetes
version.

> **When you add a policy, add at least one test case for it in the same PR.** A policy with no test is
> indistinguishable from a policy that silently stopped being enforced.

Conventions to follow when writing the case:

- Copy `katalog/tests/kyverno-manifests/deployment_trusted.yml` — the baseline that satisfies every
  policy — and introduce **exactly one** violation, so a rejection is attributable to a single policy.
- Assert on the policy's `validate.message`, not just on a non-zero exit code: a malformed manifest also
  exits non-zero, so an exit-code-only test can pass while the policy does nothing.
- Where policies overlap, choose a violation only the target rejects (`CHOWN`, for instance, is accepted
  by `disallow-capabilities` but refused by `disallow-capabilities-strict`).
- Add an `[ALLOW]` case too when the policy uses `anyPattern`, `deny` or `foreach` — those paths can
  regress towards denying everything, which a deny-only test cannot detect.
- Keep the fixtures as `Deployment`s. The policies match `kind: Pod`, so this also exercises Kyverno's
  autogen of rules for Pod controllers.

### What the suite does not cover

Verify these by hand when upgrading Kyverno or adding a Kubernetes version:

| Not automated | Why |
| ------------- | --- |
| Background scan re-evaluating pre-existing resources, and the `{{ request.operation \|\| 'BACKGROUND' }}` branch of the preconditions | `--backgroundScanInterval=1h`. The suite only sees reports produced by the admission path, which always carries a real operation. |
| Metrics endpoint content | Needs a pod that can reach `kyverno-svc-metrics:8000`. The suite only asserts the four ServiceMonitors exist. |
| Default registry mutation (`enableDefaultRegistryMutation`) | Needs a server-side dry-run on an unqualified image. |
| `excludeGroups: system:nodes` | Needs impersonation plus RBAC for the impersonated identity. |
| `resourceFilters`, `generateSuccessEvents`, `webhookAnnotations`, `updateRequestThreshold` | Configuration only: either no observable effect on kind, or only under load. |
| In-place upgrade from the previous release | Needs its own pipeline that deploys the previous tag first. |
