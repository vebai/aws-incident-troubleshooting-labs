# Incident 08 — The Alarm That Never Fired

**Optional exercise.** A monitoring alarm appears reassuring when it should be investigated. The book provides the investigation; this page provides only the controls and safe exit.

**Requires:** Working shared Shop practice environment. Run from the repository root.

```bash
# Check the Shop, then trigger and inspect the monitoring experiment.
scripts/validate-baseline.sh
export CONFIRM_LAB_CHANGES=YES
scripts/incident.sh 08 inject
scripts/incident.sh 08 status
```

**Stop and investigate:** Use Incident 08 in the book. This exercise changes an alarm's configuration; it does not test delivery of a real notification.

**Safe reset:** `scripts/incident.sh 08 reset` only prints instructions; it does not undo the change. Terraform must restore the existing alarm.

```bash
# Propose restoring only the lab alarm.
terraform -chdir=terraform plan -target='aws_cloudwatch_metric_alarm.alb_5xx[0]' -out=incident-08-reset.tfplan
# ONLY if the plan updates exactly one alarm and no other resource:
terraform -chdir=terraform apply incident-08-reset.tfplan
# Confirm the monitoring settings and Shop remain ready.
scripts/incident.sh 08 status
scripts/validate-baseline.sh
```

Do not apply unrelated Terraform changes. Targeting is an exceptional recovery measure, not a normal deployment technique.
