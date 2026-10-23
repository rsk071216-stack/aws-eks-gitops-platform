#!/usr/bin/env bash
# Installs the pinned CLI versions used by CI into /usr/local/bin (Linux amd64).
# Used by the dev container; safe to re-run.
set -euo pipefail

KIND_VERSION="v0.33.0"
KUBECTL_VERSION="v1.35.8"
HELM_VERSION="v4.3.0"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

curl -fsSLo "${tmp}/kind" "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
curl -fsSLo "${tmp}/kubectl" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar -xz -C "${tmp}" linux-amd64/helm

sudo install -m 0755 "${tmp}/kind" "${tmp}/kubectl" "${tmp}/linux-amd64/helm" /usr/local/bin/
kind version && kubectl version --client && helm version --short
