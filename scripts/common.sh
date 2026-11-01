#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TF="$ROOT/terraform"
command -v aws >/dev/null; command -v terraform >/dev/null
value() { terraform -chdir="$TF" output -raw "$1"; }
REGION=$(value region)
AWS_DEFAULT_REGION="$REGION"; export AWS_DEFAULT_REGION
ASG=$(value asg_name)
BUCKET=$(value bucket)
ALB_URL=$(value alb_url)
ROLE=$(value instance_role)
TG=$(value target_group_arn)
APP_SG=$(value app_security_group_id)
ALB_SG=$(value alb_security_group_id)
ALARM=$(value alarm_name)
instance() { aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text; }
confirm() {
  echo "Account: $(aws sts get-caller-identity --query Account --output text), Region: $REGION, ASG: $ASG"
  [[ "${CONFIRM_LAB_CHANGES:-}" == YES ]] || { echo 'Set CONFIRM_LAB_CHANGES=YES before changing lab resources'; exit 1; }
}
ssm() {
  local id; id=$(instance)
  [[ "$id" != None && -n "$id" ]] || { echo 'No ASG instance'; exit 1; }
  aws ssm send-command --instance-ids "$id" --document-name AWS-RunShellScript --parameters "commands=$1" --query 'Command.CommandId' --output text
}
