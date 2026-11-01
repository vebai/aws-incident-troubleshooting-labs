#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
echo "Shop URL $ALB_URL"
for path in healthz readyz catalog; do
 code=$(curl --max-time 15 -s -o /dev/null -w '%{http_code}' "$ALB_URL/$path" || true)
 echo "$path: $code"
 [[ "$code" == 200 ]] || exit 1
done
aws elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[].{Instance:Target.Id,Health:TargetHealth.State,Reason:TargetHealth.Reason}' --output table
printf 'Baseline healthy: PASS\n'
