# Architecture Decision Records

Short, dated records of the decisions that shape this platform. Each one states
the context, the decision and its consequences, so a new engineer (or a client)
can see *why* things are the way they are.

| ADR | Decision | Status |
|-----|----------|--------|
| [0001](0001-pod-identity-over-irsa.md) | EKS Pod Identity instead of IRSA | Accepted |
| [0002](0002-promote-by-digest.md) | Build once, promote by image digest | Accepted |
| [0003](0003-applicationset-and-gitops-bridge.md) | ApplicationSets + GitOps bridge for environments and add-ons | Accepted |
| [0004](0004-s3-native-state-locking.md) | S3 native state locking instead of DynamoDB | Accepted |
| [0005](0005-access-entries-over-aws-auth.md) | EKS access entries instead of the aws-auth ConfigMap | Accepted |
| [0006](0006-single-nat-gateway-default.md) | Single NAT gateway by default, per-AZ as a switch | Accepted |
