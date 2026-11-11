# Incident 10 — Compound Failure (Alternative Live Exercise)

**Optional alternative exercise.** The book's illustrated incident involves an ALB security-group reference, a readiness environment mismatch, and an alarm pointing at old resources. **This live lab intentionally uses different faults**: an IAM S3 explicit deny (Incident 02), a CloudWatch metric dimension error (Incident 08), and a stopped systemd application service (Incident 03). Do not expect the book's exact HTTP 504, readiness logs, or security-group evidence in this lab.

**Requires:** A dedicated sandbox, a healthy one-instance shared Shop environment, a correctly configured baseline alarm and no leftover earlier incidents. The exercise introduces several independent failures. No single `10 inject` command exists.

## Establish the healthy baseline and inject

```bash
aws sts get-caller-identity
scripts/validate-baseline.sh
terraform -chdir=terraform plan
export CONFIRM_LAB_CHANGES=YES
# Introduce the independent failures in a controlled order.
scripts/incident.sh 02 inject
scripts/incident.sh 08 inject
scripts/incident.sh 03 inject
# Record initial evidence without interpreting it.
scripts/incident.sh 02 status
scripts/incident.sh 08 status
scripts/incident.sh 03 status
```

**Stop and investigate.** Use the EVIDENCE framework from the book. Test the customer-facing `/catalog` endpoint, local service state, IAM policy evaluation and the configured metric dimensions. Record observed HTTP codes rather than expecting the book's illustrated 504. SSM commands must finish with `Success` before you regard the injection as applied. A failure during injection may leave a partially injected lab; proceed to the recovery sequence for changes that actually succeeded.

## Controlled recovery (not an answer key)

```bash
# Restore the service, then remove the explicit IAM deny.
scripts/incident.sh 03 reset
scripts/incident.sh 02 reset
# Restore the Terraform-managed alarm; review the plan before applying.
terraform -chdir=terraform plan -target='aws_cloudwatch_metric_alarm.alb_5xx[0]' -out=incident-10-reset.tfplan
# Apply ONLY if the plan contains exactly the intended alarm repair.
terraform -chdir=terraform apply incident-10-reset.tfplan
scripts/incident.sh 08 status
scripts/validate-baseline.sh
terraform -chdir=terraform plan
```

**Closure proof:** Confirm that the application responds to `/healthz`, `/readyz` and `/catalog`; target health is restored; the injected inline IAM deny is absent; the CloudWatch alarm contains both `LoadBalancer` and `TargetGroup`; and the complete Terraform plan shows no unexpected changes. Preserve evidence when a step fails. Restore the healthy baseline before another incident.
