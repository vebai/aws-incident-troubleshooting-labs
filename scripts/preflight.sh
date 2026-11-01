#!/usr/bin/env bash
set -euo pipefail
command -v aws >/dev/null || { echo 'AWS CLI v2 required'; exit 1; }
command -v terraform >/dev/null || { echo 'Terraform required'; exit 1; }
aws sts get-caller-identity --query '{Account:Account,Arn:Arn}' --output json
aws configure get region || true
terraform version | head -n 2
printf '\nReview account, region, quotas, public HTTP CIDRs, IAM and costs before deployment.\n'
