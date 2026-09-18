#!/usr/bin/env bats
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# shellcheck disable=SC2154

load helper

set -o pipefail

@test "Deploy Kyverno" {
  info
  deploy() {
    kubectl apply -f 'https://raw.githubusercontent.com/sighupio/module-monitoring/refs/tags/v4.2.0/katalog/prometheus-operator/crds/0servicemonitorCustomResourceDefinition.yaml'
    kubectl apply -f 'https://raw.githubusercontent.com/sighupio/module-monitoring/refs/tags/v4.2.0/katalog/prometheus-operator/crds/0prometheusruleCustomResourceDefinition.yaml'
    # Ensure monitoring CRDs are established before applying resources that use them
    kubectl wait --for=condition=Established \
      crd/servicemonitors.monitoring.coreos.com \
      crd/prometheusrules.monitoring.coreos.com \
      --timeout=10m

    # Apply Kyverno CRDs and wait until they are established instead of sleeping
    kubectl apply -f katalog/kyverno/core/crds.yaml --server-side
    kubectl wait -f katalog/kyverno/core/crds.yaml \
      --for=condition=Established \
      --timeout=10m
    force_apply katalog/kyverno
  }
  loop_it deploy 30 2
  status=${loop_it_result}
  [[ "$status" -eq 0 ]]
}

@test "Kyverno is Running" {
  info
  # Wait for all Kyverno controllers to roll out
  run kubectl rollout status deployment/kyverno-admission-controller -n kyverno --timeout=10m
  [ "$status" -eq 0 ]

  run kubectl rollout status deployment/kyverno-background-controller -n kyverno --timeout=10m
  [ "$status" -eq 0 ]

  run kubectl rollout status deployment/kyverno-cleanup-controller -n kyverno --timeout=10m
  [ "$status" -eq 0 ]

  run kubectl rollout status deployment/kyverno-reports-controller -n kyverno --timeout=10m
  [ "$status" -eq 0 ]
}

# [ALLOW] Allowed by Gatekeeper Kubernetes requests

@test "[ALLOW] Deployment in a Whitelisted Namespace (kube-system)" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deploy_ns_whitelisted.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "[ALLOW] Deployment with every required attributes" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_trusted.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}


@test "[ALLOW] Create not existing Ingress" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/ingress_trusted.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

# [DENY] Denied by Gatekeeper Kubernetes requests

@test "[DENY] Deployment using latest tag" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_reject_label_latest.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Using a mutable image tag"* ]]
}

@test "[DENY] Pod without liveness/readiness probes" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/pod-rejected-without-livenessProbe.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"validate-probes"* ]]
}

@test "[DENY] Duplicated ingress" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/ingress_rejected_duplicated.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"unique-ingress-host-and-path"* ]]
}

# ---------------------------------------------------------------------------
# Policy coverage.
#
# Each manifest below is katalog/tests/kyverno-manifests/deployment_trusted.yml
# with exactly one deliberate change, so a rejection is attributable to a single
# policy. Assertions match on the policy's own message rather than on a bare
# non-zero exit, because an invalid manifest would also exit non-zero and would
# otherwise look like a passing test.
#
# The [ALLOW] cases matter as much as the [DENY] ones: `anyPattern`, `deny`
# conditions and `foreach` could all regress towards denying everything, which
# would look healthy until a legitimate workload is blocked.
# ---------------------------------------------------------------------------

@test "[DENY] Deployment with a privileged container" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_privileged.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Privileged mode is disallowed"* ]]
}

@test "[DENY] Deployment allowing privilege escalation" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_privilege_escalation.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Privilege escalation is disallowed"* ]]
}

@test "[DENY] Deployment sharing a host namespace" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_host_namespaces.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Sharing the host namespaces is disallowed"* ]]
}

@test "[DENY] Deployment with a hostPath volume" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_host_path.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"HostPath volumes are forbidden"* ]]
}

@test "[DENY] Deployment binding a host port" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_host_port.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Use of host ports is disallowed"* ]]
}

@test "[DENY] Deployment with a non-default procMount" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_proc_mount.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Changing the proc mount from the default is not allowed"* ]]
}

@test "[DENY] Deployment with a disallowed sysctl" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_sysctls.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Setting additional sysctls above the allowed type is disallowed"* ]]
}

@test "[DENY] Deployment that may run as root" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_run_as_root.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Running as root is not allowed"* ]]
}

@test "[DENY] Deployment adding a capability outside the allowed list" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_capabilities.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Any capabilities added beyond the allowed list"* ]]
}

# CHOWN is accepted by disallow-capabilities but not by the strict policy, which
# permits NET_BIND_SERVICE alone. This isolates the strict policy from the lenient one.
@test "[DENY] Deployment adding a capability disallowed only by the strict policy" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_capabilities_strict.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Any capabilities added other than NET_BIND_SERVICE are disallowed"* ]]
}

@test "[DENY] Deployment that does not drop ALL capabilities" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_rejected_no_drop_all.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Containers must drop"* ]]
}

@test "[ALLOW] Deployment with an allowed sysctl" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_allowed_sysctls.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

# Exercises the first anyPattern branch: runAsNonRoot satisfied at pod level
# rather than on each container.
@test "[ALLOW] Deployment setting runAsNonRoot at pod level" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_allowed_run_as_nonroot_pod_level.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "[ALLOW] Deployment adding only NET_BIND_SERVICE" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/deployment_allowed_capabilities.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

# ---------------------------------------------------------------------------
# Deployment-level checks.
#
# These cover the conditions that are not policy evaluation but that policy
# enforcement silently depends on: policy readiness, autogen for pod
# controllers, webhook registration, namespace exclusion and the state of the
# four controllers. A regression in any of them leaves the cluster looking
# healthy while policies quietly stop being applied.
# ---------------------------------------------------------------------------

@test "[CHECK] Every default policy is installed and Ready" {
  info
  # .status.ready is deprecated upstream in favour of conditions, so assert on
  # the Ready condition. The controllers have already rolled out by this point,
  # so a short timeout is enough and keeps a regression from stalling the job.
  run kubectl wait --for=condition=Ready clusterpolicy --all --timeout=2m
  [ "$status" -eq 0 ]

  # The cluster must hold exactly the policies shipped in the katalog, so adding
  # a policy file without it reaching the cluster fails here.
  expected=$(find katalog/kyverno/policies/collection -name '*.yaml' | wc -l | tr -d ' ')
  actual=$(kubectl get clusterpolicy --no-headers | wc -l | tr -d ' ')
  echo "policies in katalog: ${expected}, in cluster: ${actual}" >&3
  [ "$actual" -eq "$expected" ]
}

@test "[CHECK] Autogen rules are generated for pod controllers" {
  info
  # Every policy matches kind Pod only; enforcement on Deployments and friends
  # depends entirely on Kyverno autogenerating the controller rules.
  failed=""
  for p in $(kubectl get clusterpolicy -o jsonpath='{.items[*].metadata.name}'); do
    # matches Ingress, nothing to autogen
    [ "$p" = "unique-ingress-host-and-path" ] && continue
    count=$(kubectl get clusterpolicy "$p" -o jsonpath='{.status.autogen.rules[*].name}' | wc -w | tr -d ' ')
    echo "  ${p}: ${count} autogen rule(s)" >&3
    [ "$count" -gt 0 ] || failed="${failed} ${p}"
  done
  echo "policies without autogen rules:${failed:- none}" >&3
  [ -z "$failed" ]
}

@test "[CHECK] require-pod-probes autogen stays restricted to the annotated controllers" {
  info
  run kubectl get clusterpolicy require-pod-probes \
    -o jsonpath='{.metadata.annotations.pod-policies\.kyverno\.io/autogen-controllers}'
  [ "$status" -eq 0 ]
  [ "$output" = "DaemonSet,Deployment,StatefulSet" ]

  # The annotation must actually take effect: no CronJob/Job rule may be generated.
  rules=$(kubectl get clusterpolicy require-pod-probes -o jsonpath='{.status.autogen.rules[*].name}')
  echo "autogen rules: ${rules}" >&3
  [[ "$rules" != *cronjob* ]]
}

@test "[ALLOW] CronJob without probes is not caught by require-pod-probes" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/cronjob_allowed_without_probes.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "[DENY] StatefulSet without probes is caught by require-pod-probes" {
  info
  deploy() {
    kubectl apply -f katalog/tests/kyverno-manifests/statefulset_rejected_without_probes.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"validate-probes"* ]]
}

@test "[CHECK] No ValidatingAdmissionPolicy is generated from the policies" {
  info
  # We deploy with --generateValidatingAdmissionPolicy=false on purpose: we do
  # not want Kyverno emitting native VAP objects.
  generated=$(kubectl get clusterpolicy \
    -o jsonpath='{range .items[*]}{.metadata.name}={.status.validatingadmissionpolicy.generated}{"\n"}{end}' \
    | grep '=true$' || true)
  echo "policies reporting a generated VAP: ${generated:-none}" >&3
  [ -z "$generated" ]

  run kubectl get deployment kyverno-admission-controller -n kyverno \
    -o jsonpath='{.spec.template.spec.containers[*].args}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"--generateValidatingAdmissionPolicy=false"* ]]
}

@test "[CHECK] Kyverno controllers have not restarted" {
  info
  # The rollout checks above pass even for a pod that crash-looped and settled.
  restarted=$(kubectl get pods -n kyverno -l app.kubernetes.io/part-of=kyverno \
    -o jsonpath='{range .items[*]}{.metadata.name}={.status.containerStatuses[*].restartCount}{"\n"}{end}' \
    | grep -v '=0$' || true)
  echo "pods with restarts: ${restarted:-none}" >&3
  [ -z "$restarted" ]
}

@test "[CHECK] Kyverno controller logs are free of panics" {
  info
  # There are 9 pods, above the default --max-log-requests of 5; without raising
  # it the command errors and the assertions below would pass on empty output.
  logs=$(kubectl logs -n kyverno -l app.kubernetes.io/part-of=kyverno \
    --tail=500 --prefix --max-log-requests=20)
  [ -n "$logs" ]
  [[ "$logs" != *"panic:"* ]]
  [[ "$logs" != *"failed to create webhook"* ]]
}

@test "[CHECK] Kyverno images are served by the SIGHUP registry at the katalog version" {
  info
  # Guards the kustomize image override and catches a chart regeneration that
  # reintroduces upstream image names.
  expected=$(grep -oE 'reg\.kyverno\.io/kyverno/kyverno:v[0-9.]+' katalog/kyverno/core/deploy.yaml \
    | head -1 | sed 's/.*://')
  echo "expected tag from katalog: ${expected}" >&3
  [ -n "$expected" ]

  images=$(kubectl get deployment -n kyverno \
    -o jsonpath='{range .items[*]}{range .spec.template.spec.containers[*]}{.image}{"\n"}{end}{range .spec.template.spec.initContainers[*]}{.image}{"\n"}{end}{end}' \
    | sed '/^$/d')
  echo "${images}" >&3

  wrong_registry=$(echo "${images}" | grep -v '^registry.sighup.io/fury/kyverno/' || true)
  [ -z "$wrong_registry" ]

  wrong_tag=$(echo "${images}" | grep -v ":${expected}$" || true)
  [ -z "$wrong_tag" ]
}

@test "[CHECK] Admission webhooks are registered for pods and their controllers" {
  info
  cfg=$(kubectl get validatingwebhookconfiguration -o name | grep 'kyverno-resource-validating' | head -1)
  echo "webhook configuration: ${cfg}" >&3
  [ -n "$cfg" ]

  resources=$(kubectl get "$cfg" -o jsonpath='{.webhooks[*].rules[*].resources[*]}')
  echo "resources: ${resources}" >&3
  [[ "$resources" == *pods* ]]
  # present only because autogen reached the webhook
  [[ "$resources" == *deployments* ]]

  # Ignore would mean requests sail through whenever Kyverno is unavailable.
  policies=$(kubectl get "$cfg" -o jsonpath='{.webhooks[*].failurePolicy}')
  echo "failurePolicy: ${policies}" >&3
  [[ "$policies" != *Ignore* ]]
}

@test "[CHECK] Infra namespaces are excluded from the webhooks" {
  info
  cfg=$(kubectl get validatingwebhookconfiguration -o name | grep 'kyverno-resource-validating' | head -1)
  selector=$(kubectl get "$cfg" -o jsonpath='{.webhooks[*].namespaceSelector}')
  echo "namespaceSelector: ${selector}" >&3
  for ns in kube-system kyverno logging monitoring ingress-nginx cert-manager; do
    [[ "$selector" == *"$ns"* ]]
  done
}

@test "[CHECK] Monitoring and disruption budgets are in place" {
  info
  pdbs=$(kubectl get poddisruptionbudget -n kyverno --no-headers | wc -l | tr -d ' ')
  monitors=$(kubectl get servicemonitor -n kyverno --no-headers | wc -l | tr -d ' ')
  echo "pdbs: ${pdbs}, servicemonitors: ${monitors}" >&3
  [ "$pdbs" -eq 4 ]
  [ "$monitors" -eq 4 ]
}

@test "[CHECK] Kyverno controllers keep their hardened security context" {
  info
  # Never loosen these to make something pass.
  for c in admission background cleanup reports; do
    d="kyverno-${c}-controller"
    nonroot=$(kubectl get deployment "$d" -n kyverno -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsNonRoot}')
    escalation=$(kubectl get deployment "$d" -n kyverno -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')
    readonly_fs=$(kubectl get deployment "$d" -n kyverno -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}')
    echo "  ${d}: runAsNonRoot=${nonroot} allowPrivilegeEscalation=${escalation} readOnlyRootFilesystem=${readonly_fs}" >&3
    [ "$nonroot" = "true" ]
    [ "$escalation" = "false" ]
    [ "$readonly_fs" = "true" ]
  done
}
