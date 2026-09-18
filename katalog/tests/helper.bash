#!/usr/bin/env bats

# shellcheck disable=SC2086,SC2154,SC2034

set -o pipefail

kaction(){
    path=$1
    verb=$2
    kustomize build $path | kubectl $verb -f - --server-side 2>&3
}

apply (){
  kustomize build $1 >&2
  kustomize build $1 | kubectl apply -f - --server-side 2>&3
}

force_apply (){
  kustomize build $1 >&2
  kustomize build $1 | kubectl apply -f - --server-side --force-conflicts 2>&3
}

delete (){
  kustomize build $1 >&2
  kustomize build $1 | kubectl delete -f - --server-side 2>&3
}

info(){
  echo -e "${BATS_TEST_NUMBER}: ${BATS_TEST_DESCRIPTION}" >&3
}

loop_it(){
  retry_counter=0
  max_retry=${2:-100}
  wait_time=${3:-2}
  run ${1}
  ko=${status}
  loop_it_result=${ko}
  while [[ ko -ne 0 ]]
  do
    if [ $retry_counter -ge $max_retry ]; then echo "Timeout waiting a condition"; return 1; fi
    sleep ${wait_time} && echo "# waiting..." $retry_counter >&3
    run ${1}
    ko=${status}
    loop_it_result=${ko}
    retry_counter=$((retry_counter + 1))
  done
  return 0
}

# Kyverno wraps long validation messages across lines in the webhook response,
# and the wrap position changes between Kyverno versions. Collapse whitespace
# before matching so message assertions survive an engine upgrade.
flatten(){
  echo "${*}" | tr -s '[:space:]' ' '
}
