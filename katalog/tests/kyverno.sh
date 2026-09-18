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
