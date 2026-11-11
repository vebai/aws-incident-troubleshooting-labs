#!/usr/bin/env bash
set -euo pipefail
# Incident 01 is standalone: do not resolve shared Shop Terraform outputs.
if [[ "${1:-}" == "01" ]]; then
 ROOT=$(cd "$(dirname "$0")/.." && pwd)
 REGION="${LAB_REGION:-eu-west-2}"
 command -v aws >/dev/null || { echo 'AWS CLI required' >&2; exit 1; }
 confirm() {
   local account
   account=$(aws sts get-caller-identity --query Account --output text) || return 1
   echo "Account: $account, lab Region: $REGION, stack: shop-context-lab"
   [[ "${CONFIRM_LAB_CHANGES:-}" == YES ]] || {
     echo 'Set CONFIRM_LAB_CHANGES=YES before changing lab resources' >&2; return 1;
   }
 }
else
 source "$(dirname "$0")/common.sh"
fi
[[ $# -eq 2 ]] || { echo 'Usage: scripts/incident.sh <01|02|03|04|05|06|08|09> <setup|inject|reset|status|cleanup>'; exit 2; }
caseid=$1; action=$2
[[ "$caseid" =~ ^(01|02|03|04|05|06|08|09)$ ]] || { echo 'Unsupported lab; see labs/README.md'; exit 2; }
[[ "$action" =~ ^(setup|inject|reset|status|cleanup)$ ]] || exit 2
if [[ "$action" != status ]]; then confirm; fi
case "$caseid:$action" in
01:setup)
 aws cloudformation deploy --stack-name shop-context-lab --template-file "$ROOT/cloudformation/incident-01/context.yaml" --region "$REGION";;
01:inject) echo 'Incident 1 is a caller Region mismatch. Temporarily set AWS_DEFAULT_REGION to another Region in a separate shell; never change infrastructure.';;
01:reset) echo "Use export AWS_DEFAULT_REGION=$REGION in your investigator shell.";;
01:status) aws cloudformation describe-stacks --stack-name shop-context-lab --region "$REGION" --query 'Stacks[0].StackStatus' --output text;;
01:cleanup) aws cloudformation delete-stack --stack-name shop-context-lab --region "$REGION";;
02:setup) "$ROOT/scripts/validate-baseline.sh";;
02:inject)
 aws iam put-role-policy --role-name "$ROLE" --policy-name ShopLabInjectedFault --policy-document "$(python3 -c 'import json,sys; print(json.dumps({"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"s3:GetObject","Resource":"arn:aws:s3:::"+sys.argv[1]+"/catalog.json"}]}))' "$BUCKET")";;
02:reset|02:cleanup) aws iam delete-role-policy --role-name "$ROLE" --policy-name ShopLabInjectedFault;;
02:status) aws iam list-role-policies --role-name "$ROLE" --query 'PolicyNames' --output table;;
03:setup|04:setup|05:setup|06:setup|08:setup) "$ROOT/scripts/validate-baseline.sh";;
03:inject) ssm 'sudo systemctl stop shop-app' ;;
03:reset|03:cleanup) ssm 'sudo systemctl start shop-app' ;;
03:status) ssm "systemctl is-active shop-app || true";;
04:inject) ssm 'sudo iptables -I INPUT 1 -p tcp --dport 8000 -j REJECT' ;;
04:reset|04:cleanup) ssm 'sudo iptables -D INPUT -p tcp --dport 8000 -j REJECT' ;;
04:status) ssm 'sudo iptables -S INPUT' ;;
05:inject) aws elbv2 modify-target-group --target-group-arn "$TG" --health-check-path /intentionally-unavailable;;
05:reset|05:cleanup) aws elbv2 modify-target-group --target-group-arn "$TG" --health-check-path /healthz;;
05:status) aws elbv2 describe-target-groups --target-group-arns "$TG" --query 'TargetGroups[0].HealthCheckPath' --output text;;
06:inject) aws s3api delete-object --bucket "$BUCKET" --key catalog.json --query '{VersionId:VersionId,DeleteMarker:DeleteMarker}' ;;
06:reset|06:cleanup)
 marker=$(aws s3api list-object-versions --bucket "$BUCKET" --prefix catalog.json --query 'DeleteMarkers[?IsLatest==`true`].VersionId|[0]' --output text)
 if [[ "$marker" != None && -n "$marker" ]]; then aws s3api delete-object --bucket "$BUCKET" --key catalog.json --version-id "$marker" >/dev/null; echo 'Latest delete marker removed'; else echo 'No current delete marker'; fi;;
06:status) aws s3api list-object-versions --bucket "$BUCKET" --prefix catalog.json --query '{Versions:Versions[].{ID:VersionId,Latest:IsLatest},Markers:DeleteMarkers[].{ID:VersionId,Latest:IsLatest}}' --output json;;
08:inject)
 # Intentionally omit the LoadBalancer dimension to reproduce the book's fault.
 tg_suffix="${TG#*targetgroup/}"
 aws cloudwatch put-metric-alarm --alarm-name "$ALARM" \
   --namespace AWS/ApplicationELB --metric-name UnHealthyHostCount \
   --dimensions "Name=TargetGroup,Value=targetgroup/$tg_suffix" \
   --statistic Maximum --period 60 --evaluation-periods 1 --threshold 0 \
   --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching;;
08:reset|08:cleanup)
  echo "MANUAL RECOVERY REQUIRED: The CloudWatch alarm has not been restored. Follow labs/incident-08/README.md to review and apply the alarm-only Terraform recovery plan, then verify alarm configuration and a full no-change Terraform plan." >&2
  exit 1;;
08:status) aws cloudwatch describe-alarms --alarm-names "$ALARM" --query 'MetricAlarms[].{Name:AlarmName,Metric:MetricName,Namespace:Namespace,State:StateValue}' --output table;;
09:setup)
 aws cloudformation deploy --stack-name shop-rollback-lab --template-file "$ROOT/cloudformation/incident-09/baseline.yaml" --parameter-overrides "VpcId=$(value vpc_id)" --region "$REGION";;
09:inject)
 aws cloudformation update-stack --stack-name shop-rollback-lab --template-body "file://$ROOT/cloudformation/incident-09/update-missing-source.yaml" --parameters "ParameterKey=VpcId,ParameterValue=$(value vpc_id)" --region "$REGION";;
09:reset) echo 'Inspect rollback events and confirm UPDATE_ROLLBACK_COMPLETE; baseline stack should remain intact.';;
09:status) aws cloudformation describe-stack-events --stack-name shop-rollback-lab --region "$REGION" --query 'StackEvents[0:12].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' --output table;;
09:cleanup) aws cloudformation delete-stack --stack-name shop-rollback-lab --region "$REGION";;
*) echo 'Unsupported action'; exit 2;;
esac
