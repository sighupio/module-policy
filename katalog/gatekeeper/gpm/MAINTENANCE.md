# Gatekeeper Policy Manager Package Maintenance

To maintain the GPM package, you'll need to keep updated [with upstream](https://github.com/sighupio/gatekeeper-policy-manager/tree/main/manifests) the following files:

- `README.md`
- `*.yaml`

For the manifests files (`*.yaml`), you'll need to download the files from upstream and diff them to the local ones. You can find the URL of each one as a comment in the first lines.

> [!NOTE]
> Our `README.md` is an overview, not a copy of upstream's: it deliberately carries no configuration
> parameters table, because this module deploys GPM without authentication and sets no `GPM_*`
> environment variables. If that changes, document the variables actually set here rather than
> mirroring upstream's full table.
