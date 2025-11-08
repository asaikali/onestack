#!/bin/bash
set -e

vendir sync

# Define the variable REPO_ROOT (Absolute path to the repository root)
REPO_ROOT=$(git rev-parse --show-toplevel)

PLATFORM_DIR=${REPO_ROOT}/platform

FLUX="${PLATFORM_DIR}/flux-system/gotk-components.yaml"
CERT_MANAGER="${PLATFORM_DIR}/cert-manager/cert-manager.yaml"
ESO="${PLATFORM_DIR}/external-secrets/external-secrets.yaml"

# Build the bootstrap manifest
echo "Running kustomize build..."
kustomize build components/flux > ${FLUX}
kustomize build components/cert-manager > ${CERT_MANAGER}

helm template external-secrets \
    components/external-secrets/upstream/chart \
    -n external-secrets \
    --create-namespace > ${ESO}


echo "Generated files:"
echo "  - ${FLUX}"
echo "  - ${CERT_MANAGER}"
echo "  - ${ESO}"
