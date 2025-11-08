#!/bin/bash
set -e

vendir sync

# Define the variable REPO_ROOT (Absolute path to the repository root)
REPO_ROOT=$(git rev-parse --show-toplevel)

PLATFORM_DIR=${REPO_ROOT}/platform

FLUX_YAML="${PLATFORM_DIR}/flux-system/gotk-components.yaml"

# Build the bootstrap manifest
echo "Running kustomize build..."
kustomize build components/flux > ${FLUX_YAML}


echo "Generated files:"
echo "  - ${FLUX_YAML}"
