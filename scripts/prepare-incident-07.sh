#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TF="$ROOT/terraform"
OUT="$ROOT/labs/incident-07/terraform/terraform.tfvars"
command -v terraform >/dev/null
command -v aws >/dev/null
if [[ -e "$OUT" ]]; then
  echo "Already exists: $OUT. Review it; delete it first if you intend to regenerate it." >&2
  exit 1
fi
get() { terraform -chdir="$TF" output -raw "$1"; }
REGION=$(get region)
VPC=$(get vpc_id)
SG=$(get app_security_group_id)
BUCKET=$(get bucket)
ASG=$(get asg_name)
LT=$(get launch_template_id)
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "Account $ACCOUNT; Region $REGION; shared VPC $VPC"
[[ "${CONFIRM_LAB_CHANGES:-}" == YES ]] || { echo 'Set CONFIRM_LAB_CHANGES=YES after confirming account and Region.' >&2; exit 1; }
SUBNET=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" --region "$REGION" --query 'AutoScalingGroups[0].VPCZoneIdentifier' --output text | cut -d, -f1)
AMI=$(aws ec2 describe-launch-template-versions --launch-template-id "$LT" --versions '$Latest' --region "$REGION" --query 'LaunchTemplateVersions[0].LaunchTemplateData.ImageId' --output text)
for v in "$SUBNET" "$AMI"; do [[ -n "$v" && "$v" != None ]] || { echo 'Failed to discover subnet or AMI' >&2; exit 1; }; done
printf 'aws_region = "%s"\nvpc_id = "%s"\nsubnet_id = "%s"\nsecurity_group_id = "%s"\nami_id = "%s"\ncatalog_bucket = "%s"\ninject_failure = true\n' "$REGION" "$VPC" "$SUBNET" "$SG" "$AMI" "$BUCKET" > "$OUT"
chmod 600 "$OUT"
printf 'Created private configuration: %s\nReview these values before using Incident 07.\n' "$OUT"
