# 0002 - Build once, promote by image digest

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

A common pattern is "re-tag and redeploy": QA runs `app:1.4.0`, and promotion
means deploying the tag `app:1.4.0` (or re-tagging it `app:prod`) in prod.
Tags are **mutable pointers**. Between the QA test and the prod deploy the tag
can be re-pushed (a re-run pipeline, a hotfix, a compromised CI token), and
prod then runs an image nobody tested. Node image caches and `IfNotPresent`
pull policies make it even harder to tell what is actually running.

## Decision

- QA tracks a release **tag** (fast feedback).
- After the QA smoke tests pass, the `promote` workflow reads the digest of the
  image the QA pods are **actually running** (`status.containerStatuses[].imageID`)
  and opens a pull request that pins the prod overlay with
  `kustomize edit set image ghcr.io/stefanprodan/podinfo@sha256:...`.
- Merging the PR is the production approval; Argo CD deploys it.
- CI rejects any prod manifest whose image is not referenced by `@sha256:`.
- ECR repositories are created with `IMMUTABLE` tags as a second line of defence.

## Consequences

- Prod runs byte-for-byte what QA tested, and Git history is a complete,
  reviewable audit log of what ran in prod and when.
- Rollback is a `git revert` of the promotion PR; the previous digest is in the PR body.
- Digests are not human-friendly, so the PR title and body carry the version.
- PRs opened with the default `GITHUB_TOKEN` do not trigger other workflows. In a
  client setup, use a GitHub App token so the promotion PR gets its own CI run.
