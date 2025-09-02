# Kyverno - maintenance

To maintain the Kyverno package, you should follow this steps.

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/

helm repo update

helm search repo kyverno/kyverno # get the latest chart version
helm pull kyverno/kyverno --version 3.3.7  --untar --untardir /tmp
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