#!/usr/bin/env bash
# Smoke-tests a podinfo deployment and prints the exact image digest it runs.
#
# Usage: scripts/smoke-test.sh <namespace> [expected-version]
#
# Used by CI (kind) and by the promote workflow. The digest printed on the last
# line ("digest=sha256:...") is what gets promoted to prod.
set -euo pipefail

NAMESPACE="${1:?namespace required}"
EXPECTED_VERSION="${2:-}"
LOCAL_PORT="${LOCAL_PORT:-19898}"

log() { printf '[smoke] %s\n' "$*" >&2; }

log "waiting for deployment/podinfo in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" rollout status deployment/podinfo --timeout=300s

kubectl -n "${NAMESPACE}" port-forward svc/podinfo "${LOCAL_PORT}:9898" >/dev/null 2>&1 &
PF_PID=$!
trap 'kill ${PF_PID} 2>/dev/null || true' EXIT

base="http://127.0.0.1:${LOCAL_PORT}"
for i in $(seq 1 30); do
  if curl -fsS "${base}/healthz" >/dev/null 2>&1; then break; fi
  [[ ${i} -eq 30 ]] && { log "port-forward never became ready"; exit 1; }
  sleep 2
done

log "GET /healthz -> $(curl -fsS "${base}/healthz")"
log "GET /readyz  -> $(curl -fsS "${base}/readyz")"

info="$(curl -fsS "${base}/")"
version="$(printf '%s' "${info}" | grep -o '"version": *"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
log "running podinfo version: ${version}"

if [[ -n "${EXPECTED_VERSION}" && "${version}" != "${EXPECTED_VERSION}" ]]; then
  log "FAIL: expected version ${EXPECTED_VERSION}, got ${version}"
  exit 1
fi

# The digest the kubelet actually pulled and is running - not what a tag
# points to *now*, which could have changed since.
image_ids="$(kubectl -n "${NAMESPACE}" get pods -l app.kubernetes.io/name=podinfo \
  -o jsonpath='{range .items[*]}{.status.containerStatuses[0].imageID}{"\n"}{end}' | sort -u)"
if [[ "$(printf '%s\n' "${image_ids}" | grep -c .)" -ne 1 ]]; then
  log "FAIL: pods run more than one image: ${image_ids}"
  exit 1
fi
digest="${image_ids##*@}"
if [[ ! "${digest}" =~ ^sha256:[a-f0-9]{64}$ ]]; then
  log "FAIL: could not determine image digest from '${image_ids}'"
  exit 1
fi

log "PASS: ${NAMESPACE} healthy, version=${version}"
echo "version=${version}"
echo "digest=${digest}"
