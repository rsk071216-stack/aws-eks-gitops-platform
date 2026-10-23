# 0003 - ApplicationSets and the GitOps bridge

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

Hand-written Argo CD `Application` objects per environment drift apart and get
copy-pasted. Cluster add-ons also need values only Terraform knows (cluster
name, region, VPC ID), and hard-coding them in Git couples the repo to one account.

## Decision

- **Root app-of-apps** (`gitops/bootstrap/root-app.yaml`) is the only object
  applied by hand; it syncs `gitops/argocd/`.
- **Workloads:** an `ApplicationSet` with a **Git directory generator** creates
  one Application per folder under `apps/podinfo/overlays/` (`podinfo-qa`,
  `podinfo-prod`). A new environment is a new folder.
- **Add-ons:** pinned Helm chart versions. The AWS Load Balancer Controller uses
  a **cluster generator**: `scripts/bootstrap-argocd.sh` writes Terraform outputs
  as annotations on the Argo CD cluster Secret (the "GitOps bridge" pattern),
  and the ApplicationSet templates them into Helm values. Clusters opt in with
  a label, so kind clusters in CI never try to install it.
- Two `AppProject`s separate platform add-ons from workloads; workloads may only
  target `podinfo-*` namespaces from this repository.

## Consequences

- Terraform and GitOps have a small, explicit contract (a handful of annotations).
- Multi-cluster is a matter of registering more cluster Secrets.
- The same ApplicationSet is exercised in CI; only the Git revision is swapped
  to the commit under test.
