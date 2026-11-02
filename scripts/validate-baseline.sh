#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
echo "Shop URL $ALB_URL"
for path in healthz readyz catalog; do
 code=$(curl --max-time 15 -s -o /dev/null -w '%{http_code}' "$ALB_URL/$path" || true)
 echo "$path: $code"
 [[ "$code" == 200 ]] || exit 1
done
# Display the ALB target-health evidence.
aws elbv2 describe-target-health \
  --target-group-arn "$TG" \
  --query 'TargetHealthDescriptions[].{Instance:Target.Id,Health:TargetHealth.State,Reason:TargetHealth.Reason}' \
  --output table

# A healthy baseline requires at least one registered target,
# with every registered target in the healthy state.
total=$(aws elbv2 describe-target-health \
  --target-group-arn "$TG" \
  --query 'length(TargetHealthDescriptions[])' \
  --output text)

unhealthy=$(aws elbv2 describe-target-health \
  --target-group-arn "$TG" \
  --query "length(TargetHealthDescriptions[?TargetHealth.State!='healthy'])" \
  --output text)

if [[ "$total" -eq 0 ]]; then
  echo "Baseline healthy: FAIL — no registered ALB targets" >&2
  exit 1
fi

if [[ "$unhealthy" -ne 0 ]]; then
  echo "Baseline healthy: FAIL — $unhealthy of $total targets are not healthy" >&2
  exit 1
fi

printf 'Baseline healthy: PASS\n'