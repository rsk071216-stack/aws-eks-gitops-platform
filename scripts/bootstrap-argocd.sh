#!/usr/bin/env bash
# Installs Argo CD on the EKS cluster created by terraform/ and hands control
# to GitOps. Run once after `terraform apply`.
#
# Requirements: aws CLI, kubectl, helm, jq, terraform (state initialised).
set -euo pipefail

ARGOCD_CHART_VERSION="10.9.5" # argo-cd Helm chart -> Argo CD v3.5.3
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '[bootstrap] %s\n' "$*"; }

log "reading cluster metadata from terraform outputs"
meta="$(terraform -chdir="${REPO_ROOT}/terraform" output -json gitops_metadata)"
cluster_name="$(jq -r .aws_cluster_name <<<"${meta}")"
region="$(jq -r .aws_region <<<"${meta}")"
vpc_id="$(jq -r .aws_vpc_id <<<"${meta}")"
account_id="$(jq -r .aws_account_id <<<"${meta}")"

log "updating kubeconfig for ${cluster_name} (${region})"
aws eks update-kubeconfig --region "${region}" --name "${cluster_name}"

log "installing Argo CD chart ${ARGOCD_CHART_VERSION}"
helm upgrade --install argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm \
  --version "${ARGOCD_CHART_VERSION}" \
  --namespace argocd --create-namespace \
  --values "${REPO_ROOT}/gitops/bootstrap/argocd-values.yaml" \
  --wait --timeout 10m

# GitOps bridge: register the local cluster with labels (feature flags) and
# annotations (AWS facts from Terraform) that add-on ApplicationSets consume.
log "registering in-cluster with GitOps bridge metadata"
kubectl apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: in-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    enable_aws_load_balancer_controller: "true"
  annotations:
    aws_cluster_name: "${cluster_name}"
    aws_region: "${region}"
    aws_vpc_id: "${vpc_id}"
    aws_account_id: "${account_id}"
type: Opaque
stringData:
  name: in-cluster
  server: https://kubernetes.default.svc
  config: '{"tlsClientConfig":{"insecure":false}}'
YAML

log "applying the root app-of-apps"
kubectl apply -f "${REPO_ROOT}/gitops/bootstrap/root-app.yaml"

log "done. Watch progress with: kubectl -n argocd get applications -w"
log "UI: kubectl -n argocd port-forward svc/argocd-server 8080:80"
log "initial admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
