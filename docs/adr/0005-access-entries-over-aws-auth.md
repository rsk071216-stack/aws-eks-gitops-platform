# 0005 - EKS access entries instead of the aws-auth ConfigMap

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

The `aws-auth` ConfigMap mapped IAM principals to Kubernetes groups. It lives
inside the cluster, a single typo can lock everyone out, and it cannot be
managed cleanly by Terraform before the cluster exists.

## Decision

- `authentication_mode = "API"`: only **EKS access entries** are honoured.
- Admins get `AmazonEKSClusterAdminPolicy` at cluster scope.
- Developers get `AmazonEKSEditPolicy` scoped to the `podinfo-qa` namespace
  only: least privilege without writing RBAC YAML.
- Access is managed through the EKS API (Terraform) and audited in CloudTrail.

## Consequences

- No in-cluster object can lock out administrators.
- Fine-grained custom permissions still use Kubernetes RBAC, bound to the
  group names assigned in access entries.
