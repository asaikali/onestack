#!/bin/bash
set -e

vendir sync

# Define the variable REPO_ROOT (Absolute path to the repository root)
REPO_ROOT=$(git rev-parse --show-toplevel)

PLATFORM_DIR=${REPO_ROOT}/platform

FLUX_YAML="${PLATFORM_DIR}/flux-system/gotk-components.yaml"
CERT_MANER="${PLATFORM_DIR}/cert-manager/cert-manager.yaml"

# Build the bootstrap manifest
echo "Running kustomize build..."
kustomize build components/flux > ${FLUX_YAML}
kustomize build components/cert-manager > ${CERT_MANER}


echo "Generated files:"
echo "  - ${FLUX_YAML}"
echo "  - ${CERT_MANER}"
