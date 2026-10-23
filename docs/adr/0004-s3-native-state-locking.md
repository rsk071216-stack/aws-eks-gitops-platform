# 0004 - S3 native state locking instead of DynamoDB

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

The S3 backend historically needed a DynamoDB table for state locking: one more
resource to create, secure, pay for and explain. Terraform 1.10 added
`use_lockfile`, which writes a `.tflock` object next to the state using S3
conditional writes, and Terraform 1.11 deprecated the DynamoDB arguments.

## Decision

- `backend "s3"` uses `use_lockfile = true` and `encrypt = true`, with
  **partial configuration**: bucket, key and region come from `backend.hcl`
  (local) or `-backend-config` flags (CI). The code is account-agnostic.
- `required_version = ">= 1.10.0"`; CI pins Terraform 1.16.5.
- The state bucket (`terraform/bootstrap`) is versioned, KMS-encrypted,
  TLS-only, public-access-blocked and protected with `prevent_destroy`.

## Consequences

- No DynamoDB table. Lock behaviour is the same for users
  (`terraform force-unlock` still works).
- Teams on Terraform older than 1.10 must upgrade before using this backend.
- The bootstrap stack itself uses local state (chicken-and-egg). It is tiny and
  can be migrated into the bucket after the first apply.
