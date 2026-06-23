#!/usr/bin/env bash
set -euo pipefail

namespace="${NAMESPACE:-openupf}"

kubectl create namespace "${namespace}" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "${namespace}" create configmap openupf-config \
  --from-file=smu_docker.ini=config/smu/smu_docker.ini \
  --from-file=fpu_dpdk_docker.ini=config/fpu/fpu_dpdk_docker.ini \
  --from-file=lbu_docker.ini=config/lbu/lbu_docker.ini \
  --dry-run=client -o yaml | kubectl apply -f -
