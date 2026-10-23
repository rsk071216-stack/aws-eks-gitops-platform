#!/usr/bin/env bash
# Spins up the full GitOps flow locally on kind (no AWS account needed):
# kind cluster -> Argo CD -> AppProjects + podinfo ApplicationSet -> qa + prod.
#
# Usage: scripts/local-up.sh            # tracks the main branch on GitHub
#        REVISION=<sha|branch> scripts/local-up.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-gitops-demo}"
REVISION="${REVISION:-main}"
KIND_NODE_IMAGE="kindest/node:v1.35.8@sha256:07b2536e30b803ed61d1677a79df6115f798ce64c80f9e22f6ed45afd09323c0"
ARGOCD_CHART_VERSION="10.9.5"

log() { printf '[local-up] %s\n' "$*"; }

if ! kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  log "creating kind cluster ${CLUSTER_NAME}"
  kind create cluster --name "${CLUSTER_NAME}" --image "${KIND_NODE_IMAGE}" \
    --config "${REPO_ROOT}/.github/kind-config.yaml" --wait 120s
fi

log "installing Argo CD (chart ${ARGOCD_CHART_VERSION})"
helm upgrade --install argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm --version "${ARGOCD_CHART_VERSION}" \
  --namespace argocd --create-namespace \
  --values "${REPO_ROOT}/gitops/bootstrap/argocd-values.yaml" --wait --timeout 10m

log "applying AppProjects and the podinfo ApplicationSet (revision ${REVISION})"
kubectl apply -f "${REPO_ROOT}/gitops/argocd/projects.yaml"
sed -e "s|revision: main|revision: ${REVISION}|" -e "s|targetRevision: main|targetRevision: ${REVISION}|" \
  "${REPO_ROOT}/gitops/argocd/workloads-podinfo.yaml" | kubectl apply -f -

log "waiting for podinfo-qa to become Healthy"
until kubectl -n argocd get application podinfo-qa >/dev/null 2>&1; do sleep 5; done
kubectl -n argocd wait application/podinfo-qa --for=jsonpath='{.status.health.status}'=Healthy --timeout=600s

bash "${REPO_ROOT}/scripts/smoke-test.sh" podinfo-qa

cat <<MSG

Done. Next steps:
  kubectl -n argocd get applications
  kubectl -n podinfo-qa port-forward svc/podinfo 9898:9898        # http://localhost:9898
  kubectl -n argocd port-forward svc/argocd-server 8080:80        # http://localhost:8080 (user: admin)
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
  kind delete cluster --name ${CLUSTER_NAME}                       # clean up
MSG
