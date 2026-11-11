#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TF="$ROOT/terraform"
command -v aws >/dev/null; command -v terraform >/dev/null
value() { terraform -chdir="$TF" output -raw "$1"; }
REGION=$(value region)
LAB_ACCOUNT=$(value account_id)
ACTUAL_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [[ -z "$LAB_ACCOUNT" || "$LAB_ACCOUNT" == None || "$ACTUAL_ACCOUNT" != "$LAB_ACCOUNT" ]]; then
  echo "ERROR: Terraform lab account ($LAB_ACCOUNT) does not match active AWS credentials ($ACTUAL_ACCOUNT)." >&2
  echo "Switch to the correct sandbox profile before running any incident command." >&2
  exit 1
fi
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
  local id command_id status

  id=$(instance)

  if [[ -z "$id" || "$id" == "None" ]]; then
    echo "ERROR: No Auto Scaling instance found." >&2
    return 1
  fi

  command_id=$(aws ssm send-command \
    --instance-ids "$id" \
    --document-name AWS-RunShellScript \
    --parameters "commands=$1" \
    --region "$REGION" \
    --query 'Command.CommandId' \
    --output text) || return 1

  echo "SSM command submitted: $command_id"

  if ! aws ssm wait command-executed \
    --command-id "$command_id" \
    --instance-id "$id" \
    --region "$REGION"; then

    echo "ERROR: SSM command did not complete successfully." >&2

    aws ssm get-command-invocation \
      --command-id "$command_id" \
      --instance-id "$id" \
      --region "$REGION" \
      --query '{Status:Status,Details:StatusDetails,Error:StandardErrorContent}' \
      --output json || true

    return 1
  fi

  status=$(aws ssm get-command-invocation \
    --command-id "$command_id" \
    --instance-id "$id" \
    --region "$REGION" \
    --query 'Status' \
    --output text) || return 1

echo "SSM execution status: $status"

aws ssm get-command-invocation \
  --command-id "$command_id" \
  --instance-id "$id" \
  --region "$REGION" \
  --query 'StandardOutputContent' \
  --output text || return 1

[[ "$status" == "Success" ]]
}
