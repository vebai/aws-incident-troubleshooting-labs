# Incident 10 — The Outage That Hid Three Failures

**Optional exercise.** A single outage hides more than one independent problem. The book provides the investigation; this page provides only the controls and safe exit.

**Requires:** Working shared Shop application, correct alarm settings, and no leftover fault from another exercise. **No single `10 inject` command exists**; this uses tested controls one at a time.

```bash
# Check the practice application and enable lab changes.
scripts/validate-baseline.sh
export CONFIRM_LAB_CHANGES=YES
# Introduce the three controlled changes in sequence.
scripts/incident.sh 02 inject
scripts/incident.sh 08 inject
scripts/incident.sh 03 inject
# Record initial observations, not a diagnosis.
scripts/incident.sh 02 status
scripts/incident.sh 08 status
```

**Stop and investigate:** Follow Incident 10 in the book. Check that the SSM command returned by Incident 03 actually succeeded.

**Safe recovery:** Restore each controlled change, then check the entire Shop. These commands are for safe recovery, not a diagnostic walkthrough.

```bash
# Restart the application and remove the incident IAM policy.
scripts/incident.sh 03 reset
scripts/incident.sh 02 reset
# Restore only the changed alarm; review the plan first.
terraform -chdir=terraform plan -target='aws_cloudwatch_metric_alarm.alb_5xx[0]' -out=incident-10-reset.tfplan
# ONLY if one alarm changes and no other resource:
terraform -chdir=terraform apply incident-10-reset.tfplan
# Check the complete application and monitoring settings.
scripts/incident.sh 08 status
scripts/validate-baseline.sh
```

SSM start/stop commands return a command ID; check their execution outcome. If an injected command fails partway through, use the same safe recovery steps for whichever changes succeeded.
