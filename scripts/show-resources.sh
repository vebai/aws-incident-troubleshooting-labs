#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
printf 'ALB: %s\nCatalog bucket: %s\nASG: %s\nInstance: %s\n' "$ALB_URL" "$BUCKET" "$ASG" "$(instance)"
aws autoscaling describe-scaling-activities --auto-scaling-group-name "$ASG" --max-items 5 --query 'Activities[].{Status:StatusCode,Description:Description}' --output table
aws elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[].{Instance:Target.Id,Health:TargetHealth.State}' --output table
