# 0001 - EKS Pod Identity instead of IRSA

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

Pods that call AWS APIs need credentials. Node instance profiles are shared by
every pod on the node, and static access keys are a leak waiting to happen.
IRSA (IAM Roles for Service Accounts) solved this, but every cluster needs its
own OIDC provider, and every role trust policy must list each cluster's OIDC
issuer. That is painful with blue/green cluster upgrades or many clusters.

## Decision

Use **EKS Pod Identity** (`eks-pod-identity-agent` add-on +
`aws_eks_pod_identity_association`) for every workload that needs AWS access:
the AWS Load Balancer Controller and the example `podinfo` role.

- The trust policy has a single static principal (`pods.eks.amazonaws.com`);
  roles are reusable across clusters without edits.
- The association lives in Terraform next to the role, not as an annotation in
  the Kubernetes manifest.
- Sessions carry tags (`kubernetes-namespace`, `eks-cluster-name`, ...). The
  podinfo role uses them for attribute-based access control: one role, and each
  namespace can only read its own `/<cluster>/<namespace>/*` SSM parameters.
- The node IMDS hop limit is 1, so pods cannot fall back to the node role.

## Consequences

- Requires the Pod Identity agent add-on (installed `before_compute`).
- A few very old SDKs do not support the Pod Identity credential provider; all
  current AWS SDKs do.
- Cross-account access needs role chaining (or the newer target-role option)
  rather than a direct trust.
