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
    kubectl apply -f 'https://raw.githubusercontent.com/sighupio/fury-kubernetes-monitoring/v3.3.1/katalog/prometheus-operator/crds/0servicemonitorCustomResourceDefinition.yaml'
    kubectl apply -f 'https://raw.githubusercontent.com/sighupio/fury-kubernetes-monitoring/v3.3.1/katalog/prometheus-operator/crds/0prometheusruleCustomResourceDefinition.yaml'
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
