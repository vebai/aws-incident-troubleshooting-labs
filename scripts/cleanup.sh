#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
confirm
cat <<EOF
WARNING: Destructive cleanup. Delete both CloudFormation stacks separately,
then inspect Terraform destroy plan. S3 versioning may preserve object versions;
Terraform bucket force_destroy=false prevents silent deletion of retained data.
EOF
read -r -p 'Type DELETE-LAB to proceed: ' answer
[[ "$answer" == DELETE-LAB ]] || exit 1
for stack in shop-rollback-lab shop-context-lab; do
 if aws cloudformation describe-stacks --stack-name "$stack" --region "$REGION" >/dev/null 2>&1; then
  aws cloudformation delete-stack --stack-name "$stack" --region "$REGION"
  aws cloudformation wait stack-delete-complete --stack-name "$stack" --region "$REGION"
 fi
done
terraform -chdir="$TF" plan -destroy -out=cleanup.tfplan
printf 'Inspect the destroy plan above. Apply manually using terraform -chdir=terraform apply cleanup.tfplan after handling S3 object versions.\n'
