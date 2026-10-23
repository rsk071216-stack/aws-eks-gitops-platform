#!/usr/bin/env bash
# Dumps cluster state for failed CI runs. Never fails itself.
set -uo pipefail

section() { printf '\n==================== %s ====================\n' "$*"; }

section "nodes";                 kubectl get nodes -o wide --show-labels
section "all resources";         kubectl get all -A -o wide
section "argo cd applications";  kubectl -n argocd get applications,applicationsets -o wide
section "application details";   kubectl -n argocd get applications -o yaml
section "applicationset status"; kubectl -n argocd get applicationsets -o yaml
section "events (last 100)";     kubectl get events -A --sort-by=.lastTimestamp | tail -n 100

for ns in podinfo-qa podinfo-prod; do
  if kubectl get namespace "${ns}" >/dev/null 2>&1; then
    section "describe pods ${ns}"; kubectl -n "${ns}" describe pods
    section "logs ${ns}";          kubectl -n "${ns}" logs -l app.kubernetes.io/name=podinfo --all-containers --tail=100
  fi
done

for c in argocd-application-controller argocd-applicationset-controller argocd-repo-server; do
  section "logs ${c}"
  kubectl -n argocd logs -l "app.kubernetes.io/name=${c}" --all-containers --tail=150
done
exit 0
