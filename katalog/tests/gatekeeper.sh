#!/usr/bin/env bats
# Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# shellcheck disable=SC2154

load helper

set -o pipefail

@test "Deploy pod with violations" {
  info
  deploy() {
    kubectl run bad-pod --image busybox -- sleep 5000
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "Deploy Gatekeeper Core" {
  info
  deploy() {
    sed -i  -e '/# - DELETE/s/# //g' katalog/gatekeeper/core/vwh.yml
    kubectl apply -f https://raw.githubusercontent.com/sighupio/fury-kubernetes-monitoring/refs/tags/v3.3.1/katalog/prometheus-operator/crds/0servicemonitorCustomResourceDefinition.yaml
    kubectl apply -f https://raw.githubusercontent.com/sighupio/fury-kubernetes-monitoring/refs/tags/v3.3.1/katalog/prometheus-operator/crds/0prometheusruleCustomResourceDefinition.yaml
    force_apply katalog/gatekeeper/core
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "Wait for Gatekeeper Audit" {
  info
  # Wait for the Deployment rollout to complete
  run kubectl rollout status deployment/gatekeeper-audit -n gatekeeper-system --timeout=10m
  [[ "$status" -eq 0 ]]
}

@test "Wait for Gatekeeper Core" {
  info
  # Wait for the controller-manager Deployment to become ready (3 replicas)
  run kubectl rollout status deployment/gatekeeper-controller-manager -n gatekeeper-system --timeout=10m
  [[ "$status" -eq 0 ]]
}

# We just deploy the monitoring parts to check that the apply works, but we should do some more comprehensive tests.
# Some tests we could do:
# - we could check that the serviceMonitor is actually working
# - We could check for metrics being present
# - We could check that the alerts are actually triggered
# but all these requires the monitoring module to be present.
@test "Deploy Gatekeeper Monitoring" {
  info
  deploy() {
    kaction katalog/gatekeeper/monitoring apply
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "Deploy Gatekeeper Rules - templates" {
  info
  deploy() {
    kaction katalog/gatekeeper/rules/templates apply
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "Deploy Gatekeeper Rules - constraints" {
  info
  deploy() {
    # enabling all constraints for testing purposes
    sed -i -e 's/---//g' katalog/gatekeeper/rules/constraints/kustomization.yaml
    cd  katalog/gatekeeper/rules/constraints &&\
    kustomize edit add resource must_have_namespace_label_to_be_safely_deleted.yml;\
    cd -
    # Wait for Gatekeeper to generate CRDs from the ConstraintTemplates
    # This avoids a race where constraints are applied before the CRDs exist.
    loop_it "kubectl get crd securitycontrols.constraints.gatekeeper.sh" 200 3 || return 1
    loop_it "kubectl get crd k8suniqueingresshost.constraints.gatekeeper.sh" 200 3 || return 1
    loop_it "kubectl get crd k8suniqueserviceselector.constraints.gatekeeper.sh" 200 3 || return 1
    loop_it "kubectl get crd k8slivenessprobe.constraints.gatekeeper.sh" 200 3 || return 1
    loop_it "kubectl get crd k8sreadinessprobe.constraints.gatekeeper.sh" 200 3 || return 1
    loop_it "kubectl get crd k8sprotectednamespace.constraints.gatekeeper.sh" 200 3 || return 1
    kubectl wait --for=condition=Established crd/securitycontrols.constraints.gatekeeper.sh --timeout=10m
    kubectl wait --for=condition=Established crd/k8suniqueingresshost.constraints.gatekeeper.sh --timeout=10m
    kubectl wait --for=condition=Established crd/k8suniqueserviceselector.constraints.gatekeeper.sh --timeout=10m
    kubectl wait --for=condition=Established crd/k8slivenessprobe.constraints.gatekeeper.sh --timeout=10m
    kubectl wait --for=condition=Established crd/k8sreadinessprobe.constraints.gatekeeper.sh --timeout=10m
    kubectl wait --for=condition=Established crd/k8sprotectednamespace.constraints.gatekeeper.sh --timeout=10m
    kaction katalog/gatekeeper/rules/constraints apply

  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "Deploy Gatekeeper Rules - config" {
  info
  deploy() {
    kaction katalog/gatekeeper/rules/config apply
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "Wait for CRDs" {
  info
  # Wait until CRDs exist, then wait for Established
  wait_crd() {
    local crd_name="$1"
    # Wait for CRD to be created (avoid kubectl wait failing on non-existing CRD)
    loop_it "kubectl get crd ${crd_name}" 200 3
    [ "$?" -eq 0 ]
    # Once present, wait for Established condition
    run kubectl wait --for=condition=Established "crd/${crd_name}" --timeout=10m
    [[ "$status" -eq 0 ]]
  }

  wait_crd securitycontrols.constraints.gatekeeper.sh
  wait_crd k8suniqueingresshost.constraints.gatekeeper.sh
  wait_crd k8suniqueserviceselector.constraints.gatekeeper.sh
  wait_crd k8slivenessprobe.constraints.gatekeeper.sh
  wait_crd k8sreadinessprobe.constraints.gatekeeper.sh
  wait_crd k8sprotectednamespace.constraints.gatekeeper.sh
}

@test "Deploy Gatekeeper Mutator" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/mutation.yaml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "Deploy Gatekeeper Policy Manager" {
  info
  deploy() {
    kaction katalog/gatekeeper/gpm apply
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "Wait for Gatekeeper Policy Manager" {
  info
  run kubectl rollout status deployment/gatekeeper-policy-manager -n gatekeeper-system --timeout=10m
  [[ "$status" -eq 0 ]]
}


# [ALLOW] Allowed by Gatekeeper Kubernetes requests

@test "[ALLOW] Deployment in a Whitelisted Namespace (kube-system)" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/deploy_ns_whitelisted.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "[ALLOW] Deployment with every required attributes" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/deployment_trusted.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

@test "[CHECK] Check deployment has been mutated" {
  info
  deploy() {
    kubectl get deployment -n default deployment-allowed -ojsonpath="{.metadata.annotations.owner}"
  }
  run deploy
  echo "${output}"
  [ "$status" -eq 0 ]
  [ "$output" = "sighup" ]
}

@test "[CHECK] Check deployment has NOT been mutated" {
  info
  deploy() {
    kubectl get deployment -n kube-system deployment-allowed-ns -ojsonpath="{.metadata.annotations.owner}"
  }
  run deploy
  echo "${output}"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "[ALLOW] Create not existing Ingress" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/ingress_trusted.yml
  }
  run deploy
  [[ "$status" -eq 0 ]]
}


@test "[ALLOW] Delete namespace" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/ns-can-be-deleted-with-protection-disabled.yml
    kubectl delete ns my-unprotected-namespace
  }
  run deploy
  [[ "$status" -eq 0 ]]
}

# [DENY] Denied by Gatekeeper Kubernetes requests

@test "[DENY] Deployment using latest tag" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/deployment_reject_label_latest.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"using the latest tag"* ]]
}

@test "[DENY] Deployment without resources" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/deployment_rejected_missing_resources.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"enforce-deployment-and-pod-security-controls"* ]]
}

@test "[DENY] Pod without liveness/readiness probes" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/pod-rejected-without-livenessProbe.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"liveness-probe"* ]]
}

@test "[DENY] Duplicated ingress" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/ingress_rejected_duplicated.yml
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"unique-ingress-host"* ]]
}

@test "[DENY] Delete namespace" {
  info
  deploy() {
    kubectl apply -f katalog/tests/gatekeeper-manifests/ns-cannot-be-deleted-without-protection-enabled.yml
    kubectl delete ns my-protected-namespace
  }
  run deploy
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"namespace-protected"* ]]
}

@test "[AUDIT] check violations triggered by bad-pod are present" {
  info
  # Wait for audit to report expected violations without arbitrary sleep
  run kubectl wait \
    --for=jsonpath='{.status.totalViolations}'=3 \
    k8slivenessprobe.constraints.gatekeeper.sh/liveness-probe \
    --timeout=10m
  [[ "$status" -eq 0 ]]
}
