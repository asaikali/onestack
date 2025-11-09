#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="flux-system"
COMPONENTS_URL="https://raw.githubusercontent.com/asaikali/onestack/refs/heads/main/platform/flux/flux.yaml"
CLUSTER_URL="https://raw.githubusercontent.com/asaikali/onestack/refs/heads/main/test/example-cluster/cluster.yaml"

# ANSI escape code for bold text
BOLD=$(tput bold)
RESET=$(tput sgr0)

section() {
  echo
  echo "${BOLD}$1${RESET}"
  echo
}

section "🚀 Installing Flux controllers..."
kubectl apply -f "${COMPONENTS_URL}"

section "⏳ Waiting for Flux controllers to be ready..."
kubectl -n "${NAMESPACE}" wait deploy \
  --for=condition=Available \
  --timeout=3m \
  --all

section "✅ All Flux controllers are available."

section "🔍 Verifying controller versions..."
kubectl -n "${NAMESPACE}" get deployments -o wide

section "🎉 Flux bootstrap phase complete."

section "🚀 Bootstrapping cluster..."
kubectl apply -f "${CLUSTER_URL}"
