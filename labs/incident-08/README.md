# Incident 08 — The Alarm That Never Fired

**Optional exercise.** A monitoring alarm appears reassuring when it should be investigated. The book provides the investigation; this page provides only the controls and safe exit.

**Requires:** Working shared Shop practice environment. Run from the repository root.

```bash
# Check the Shop, then trigger and inspect the monitoring experiment.
scripts/validate-baseline.sh
export CONFIRM_LAB_CHANGES=YES
scripts/incident.sh 08 inject
scripts/incident.sh 08 status
# Inspect the metric identity and dimensions, not only the alarm state.
aws cloudwatch describe-alarms --alarm-names "$(terraform -chdir=terraform output -raw alarm_name)" --query 'MetricAlarms[0].{Metric:MetricName,Dimensions:Dimensions,TreatMissingData:TreatMissingData}'
```

**Stop and investigate:** Use Incident 08 in the book. The injector deliberately omits the `LoadBalancer` dimension from the `AWS/ApplicationELB` `UnHealthyHostCount` alarm while keeping its `TargetGroup` dimension. This reproduces the book's incomplete metric identity; it does not test notification delivery. The default shared Shop baseline has one target, whereas the book illustrates two. The dimension investigation is still possible with one target.

**Safe reset:** `scripts/incident.sh 08 reset` only prints instructions; it does not undo the change. Terraform must restore the existing alarm.

```bash
# Propose restoring only the lab alarm.
terraform -chdir=terraform plan -target='aws_cloudwatch_metric_alarm.alb_5xx[0]' -out=incident-08-reset.tfplan
# ONLY if the plan updates exactly one alarm and no other resource:
terraform -chdir=terraform apply incident-08-reset.tfplan
# Confirm the monitoring settings and Shop remain ready.
scripts/incident.sh 08 status
scripts/validate-baseline.sh
terraform -chdir=terraform plan
```

Confirm that the full Terraform plan has no unexpected changes. If you deliberately stopped an application target to test the metric, restore it and verify recovery before ending the exercise.

Do not apply unrelated Terraform changes. Targeting is an exceptional recovery measure, not a normal deployment technique.
