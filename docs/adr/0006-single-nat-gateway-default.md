# 0006 - Single NAT gateway by default, per-AZ as a switch

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

Private subnets need a NAT gateway for egress (image pulls from public
registries, AWS APIs without VPC endpoints). One NAT gateway per AZ is the HA
best practice but triples the fixed cost (about 32 USD/month each, plus data
processing).

## Decision

`single_nat_gateway = true` by default (demo and non-prod), and
`single_nat_gateway = false` switches to one NAT gateway per AZ for production.

## Consequences

- Default: if the AZ hosting the NAT gateway fails, egress breaks for the other
  two AZs. Workloads that do not need egress keep serving traffic.
- Next cost and security step (roadmap): VPC endpoints for ECR, S3, STS and
  CloudWatch Logs, which cut NAT data-processing charges and keep AWS API
  traffic off the internet.
