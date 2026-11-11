#!/usr/bin/env bash
# Read-only local source checks. No AWS resources are created or changed.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
note() { printf 'CHECK: %s\n' "$*"; }
command -v bash >/dev/null || fail "bash required"
command -v python3 >/dev/null || fail "python3 required"
note "Bash syntax"
for f in scripts/*.sh; do bash -n "$f" || fail "$f"; done
note "Python syntax (no generated repository files)"
python3 -c 'import ast,pathlib; [ast.parse(p.read_text()) for p in pathlib.Path("application").glob("*.py")]'
note "Required incident guides and templates"
for i in $(seq -w 1 10); do
  [[ -s "labs/incident-$i/README.md" ]] || fail "Missing guide: $i"
done
for f in terraform/main.tf terraform/variables.tf terraform/outputs.tf \
 cloudformation/incident-01/context.yaml cloudformation/incident-09/baseline.yaml \
 cloudformation/incident-09/update-missing-source.yaml application/shop_app.py; do
  [[ -s "$f" ]] || fail "Missing: $f"
done
note "Incident 01 standalone guard, Incident 08 metric identity"
grep -Fq 'if [[ "${1:-}" == "01" ]]' scripts/incident.sh || fail "Incident 01 guard missing"
grep -Fq 'metric_name         = "UnHealthyHostCount"' terraform/main.tf || fail "Alarm metric mismatch"
grep -Fq 'TargetGroup  = aws_lb_target_group.shop.arn_suffix' terraform/main.tf || fail "TargetGroup dimension missing"
grep -Fq 'LoadBalancer = aws_lb.shop.arn_suffix' terraform/main.tf || fail "LoadBalancer dimension missing"
grep -Fq 'shop_desired_capacity' terraform/main.tf || fail "Incident 08 scaling variable missing"
if command -v terraform >/dev/null; then
  note "Terraform format check (all modules)"
  terraform fmt -check -recursive || fail "Terraform formatting differs"
  for dir in terraform labs/incident-07/terraform; do
    if [[ -d "$dir/.terraform" ]]; then
      note "Terraform validate: $dir"
      terraform -chdir="$dir" validate || fail "Terraform validate: $dir"
    else
      note "SKIP Terraform validate in $dir (not initialised; run terraform -chdir=$dir init -backend=false)"
    fi
  done
else
  note "SKIP Terraform format/validate (Terraform not installed)"
fi
if command -v aws >/dev/null; then
  note "CloudFormation template syntax (offline)"
  python3 - <<'PY'
from pathlib import Path
for p in Path('cloudformation').rglob('*.yaml'):
    data=p.read_text()
    if 'AWSTemplateFormatVersion:' not in data or 'Resources:' not in data:
        raise SystemExit(f"Malformed template skeleton: {p}")
PY
else
  note "SKIP AWS CloudFormation API validation (offline script)"
fi
printf '\nStatic repository checks: PASS (skipped checks shown above).\n'
