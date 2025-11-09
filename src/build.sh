#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Bootstrap build script
# -----------------------------------------------------------------------------
# This script:
#   1. Syncs vendored dependencies.
#   2. Builds rendered manifests for core platform components.
#   3. Writes the generated YAMLs into the platform/ directory.
#
# Dependencies:
#   - git
#   - vendir
#   - kustomize
#   - helm
# -----------------------------------------------------------------------------

# ANSI escape code for bold text
BOLD=$(tput bold)
RESET=$(tput sgr0)

section() {
  echo
  echo "${BOLD}$1${RESET}"
}

# --- Tool Version Check ------------------------------------------------------

section "🧰 Tool versions"
echo "vendir:    $(vendir version | head -n1)"
echo "kustomize: $(kustomize version | head -n1)"
echo "helm:      $(helm version --short | head -n1)"
echo

# --- Setup -------------------------------------------------------------------

# Ensure vendir syncs dependencies before building
section "🔄 Syncing dependencies with vendir..."
vendir sync

# Determine repository root
REPO_ROOT="$(git rev-parse --show-toplevel)"
PLATFORM_DIR="${REPO_ROOT}/platform"

# Output manifest paths
FLUX_OUT="${PLATFORM_DIR}/flux/flux.yaml"
CERT_MANAGER_OUT="${PLATFORM_DIR}/cert-manager/install/cert-manager.yaml"
ESO_OUT="${PLATFORM_DIR}/external-secrets/external-secrets.yaml"
ENVOY_GATEWAY_OUT="${PLATFORM_DIR}/envoy-gateway/envoy-gateway.yaml"


# --- Build Flux --------------------------------------------------------------
section "🚀 Building Flux manifests..."
kustomize build components/flux > "${FLUX_OUT}"

# --- Build Cert-Manager ------------------------------------------------------
section "🔐 Building Cert-Manager manifests..."
kustomize build components/cert-manager > "${CERT_MANAGER_OUT}"

# --- Build External Secrets Operator ----------------------------------------
section "🧩 Rendering External Secrets Operator Helm chart..."
helm template external-secrets \
  components/external-secrets/upstream/chart \
  -n external-secrets \
  --include-crds \
  --create-namespace \
  --set certController.create=false \
  --set webhook.certManager.enabled=true \
  --set webhook.certManager.cert.issuerRef.kind=ClusterIssuer \
  --set webhook.certManager.cert.issuerRef.name=platform-issuer \
  > components/external-secrets/upstream/rendered-external-secrets.yaml

echo "🏗️ Building External Secrets manifests..."
kustomize build components/external-secrets > "${ESO_OUT}"

# --- Build Envoy Gateway -----------------------------------------------------
section "🌐 Rendering Envoy Gateway Helm chart..."
helm template envoy-gateway \
  components/envoy-gateway/upstream/chart/gateway-helm \
  -n envoy-gateway-system \
  --include-crds \
  --create-namespace \
  > components/envoy-gateway/upstream/rendered-envoy-gateway.yaml

section "🏗️ Building Envoy Gateway manifests..."
kustomize build components/envoy-gateway > "${ENVOY_GATEWAY_OUT}"

# --- Summary -----------------------------------------------------------------
echo
section "✅ Build completed. Generated manifests:"
cat <<EOF
  - ${FLUX_OUT}
  - ${CERT_MANAGER_OUT}
  - ${ESO_OUT}
  - ${ENVOY_GATEWAY_OUT}
EOF
echo
