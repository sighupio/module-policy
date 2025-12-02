# Gatekeeper

<!-- <KFD-DOCS> -->

## Requirements

Minimum Kubernetes version `>=v1.18` with the API server `ValidatingAdmissionWebhook` plugin enabled.

Gatekeeper core package gets deployed by default with the following resource limits:

- CPU: 1000m
- Memory: 512Mi

Gatekeeper Policy Manager package gets deployed by default with the following resource limits:

- CPU: 500m
- Memory: 256Mi

## Fury Setup

This module can easily be added to your existing Fury setup adding to your `Furyfile.yml`:

```yaml
bases:
  (...)
  - name: opa/gatekeeper
    version: "v1.16.0"
```

Once you'll do this, you can then proceed to integrate Gatekeeper into your Kustomize project.

### Disable constraints

If you need to disable already existing constraints that are usually enabled by default,
you can just simply create a patch in Kustomize like the following one:

```yaml
patchesJson6902:
    - target:
          group: constraints.gatekeeper.sh
          version: v1beta1
          kind: K8sUniqueIngressHost # is just an example of already enabled constraints
          name: unique-ingress-host
      path: patches/dryrun.yml
```

in the `patches/allow.yml`:

```yaml
- op: "replace"
  path: "/spec/enforcementAction"
  value: "dryrun"
```

### Exclude namespaces from gatekeeper constraints

There are already a bunch of namespaces excluded by default by the rules of Gatekeeper, that are the ones
used by infra namespaces *(logging, monitoring, kube-system, ingress-nginx)*. If this subset must be modified for whatever
reason, you can just do it with a kustomize path like the following one:

```yaml
patchesJson6902:
    - target:
          group: constraints.gatekeeper.sh
          version: v1beta1
          kind: K8sUniqueIngressHost # is just an example of already enabled constraints
          name: unique-ingress-host
      path: patches/ns.yml
```

in the `patches/allow.yml`:

```yaml
- op: "replace"
  path: "/spec/match/excludedNamespaces"
  value:
      - my-ns-1
      - my-ns-2
      - my-ns-3
      - my-ns-4
```

### The naming of Constraints and ConstraintTemplates

To be more explicit, it is useful to give a verbose name to constraints, such as `all_pod_must_have_gatekeeper_namespaceselector.yml`.
In this way, the scope of the constraint that is going to be applied will be crystal clear.

For the `ConstraintTemplate` (that is the general logic — a function basically —) could be reasonable to have something
like: `k8srequiredlabels_template.yml`

#### Uninstall Constraints

To uninstall rules you first need to remove the `Constraint`, then the `constraintTemplate`:

here is an example of the following resource:

```bash
kubectl delete crd k8scontainerlimits.constraints.gatekeeper.sh # this will remove the constraint
kubectl delete constrainttemplates.templates.gatekeeper.sh k8scontainerlimits # this will remove the constraintTemplate
```

### Modify constraintTemplates rules (securityControls)

There is a `constraintTemplate` *(`securityControl`)* that enables only a few subsets of the available rules, basically
because there are a lot of rules that require pretty much effort to achieve them. If you want to enable them, you can
just make a patch with kustomize (following the examples above) and enable a part or all of them
(you can find them here: [security_controls_template.yml](rules/templates/security_controls_template.yml)

## Uninstallation

Before uninstalling Gatekeeper, be sure to clean up old `Constraints`, `ConstraintTemplates`, and
the `Config` resource in the `gatekeeper-system` namespace. This will make sure all finalizers
are removed by Gatekeeper. Otherwise, the finalizers will need to be removed manually.

### Before Uninstall, Clean Up Old Constraints

Currently, the uninstallation mechanism only removes the Gatekeeper system,
it does not remove any `ConstraintTemplate`, `Constraint`, and `Config` resources that have been created by the user,
nor does it remove their accompanying `CRDs`.

When Gatekeeper is running it is possible to remove unwanted constraints by:

- Deleting all instances of the constraint resource.
- Deleting the `ConstraintTemplate` resource, which should automatically clean up the `CRD`.
- Deleting the `Config` resource removes finalizers on synced resources.

For more details please refer to [Gatekeeper's official repository][gatekeeper-repo] and the [official Gatekeeper documentation site][gatekeeper-docs].

<!-- Links -->
[gatekeeper-repo]: https://github.com/open-policy-agent/gatekeeper
[gatekeeper-docs]: https://open-policy-agent.github.io/gatekeeper/website/docs/

<!-- </KFD-DOCS> -->
