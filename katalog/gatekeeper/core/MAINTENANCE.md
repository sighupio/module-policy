# Gatekeeper Package Maintenance

1. Check the differences with upstream manifests:

```bash
# Assuming ${PWD} == the root of the project
export GATEKEEPER_VERSION=v3.21.0
curl -l https://raw.githubusercontent.com/open-policy-agent/gatekeeper/refs/tags/v3.21.0/deploy/gatekeeper.yaml -o upstream.yaml
cat katalog/gatekeeper/core/ns.yml \
    katalog/gatekeeper/core/crd.yml \
    katalog/gatekeeper/core/sa.yml \
    katalog/gatekeeper/core/rbac.yml \
    katalog/gatekeeper/core/secret.yml \
    katalog/gatekeeper/core/svc.yml \
    katalog/gatekeeper/core/deploy.yml \
    katalog/gatekeeper/core/pdb.yml \
    katalog/gatekeeper/core/mwh.yml \
    katalog/gatekeeper/core/vwh.yml \
    > local.yml
```

> You could generate the output with `kustomize build .` also, but `kustomize` changes all the indentation and word wrapping of the original files, so you won't be able to do the diff against its output.

Replace `GATEKEEPER_VERSION` with the upstream version you want to compare with. Example: `3.11`.
You can use the link from the [installation instructions](https://open-policy-agent.github.io/gatekeeper/website/docs/install#deploying-a-release-using-prebuilt-image).

diff the generated `local.yaml` with the `upstream.yaml` file and port the needed differences to the corresponding file.

> You can also diff a single file to `upstream.yaml` to port more easily the differences.

Please notice that it is expected that some objects don't have the namespace set as in upstream, this is because the namespace is set with Kustomize.

1. Sync the new image to our registry by updating the [OPA images.yaml file container-image-sync repository](https://github.com/sighupio/container-image-sync/blob/main/modules/opa/images.yml).

2. Update the `kustomization.yaml` file with the new version in the image tag.

## Customizations

- We enable monitoring of metrics by default, so we added some parameters to scrape them.
- We delete the namespace from resources definitions, the namespace is set by Kustomize.
- We create an additional service for the audit endpoint.
