# Incident 08 — The Alarm That Never Fired

**Optional two-target exercise.** The book investigates a CloudWatch alarm whose metric identity is incomplete. This lab uses a real `AWS/ApplicationELB / UnHealthyHostCount` alarm with the correct `LoadBalancer` and `TargetGroup` dimensions, then deliberately removes `LoadBalancer`.

**Requires:** A healthy shared Shop lab, an AWS sandbox with capacity for two EC2 instances, and no faults left from previous incidents. Run from the repository root. **Do not proceed if another investigation is running.** The second instance incurs charges.

## Establish two healthy targets

Change only the private `terraform/terraform.tfvars` file (created during initial setup) to include:

```hcl
shop_desired_capacity = 2
```

Review the capacity change, then apply it:

```bash
terraform -chdir=terraform plan -out=incident-08-scale.tfplan
terraform -chdir=terraform apply incident-08-scale.tfplan
scripts/validate-baseline.sh
TG=$(terraform -chdir=terraform output -raw target_group_arn)
aws elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' --output table
```

**Verify exactly two registered, healthy targets before continuing**. Auto Scaling and ALB target registration take time. Do not introduce a failure until the second target becomes healthy.

## Inject and investigate

```bash
export CONFIRM_LAB_CHANGES=YES
scripts/incident.sh 08 inject
scripts/incident.sh 08 status
aws cloudwatch describe-alarms --alarm-names "$(terraform -chdir=terraform output -raw alarm_name)" --query 'MetricAlarms[0].{Metric:MetricName,Dimensions:Dimensions,State:StateValue,TreatMissingData:TreatMissingData}'
# Now make one of the two application instances unavailable.
scripts/incident.sh 03 inject
aws elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State,TargetHealth.Reason]' --output table
```

**Stop and investigate using Incident 08 in the book.** Allow time for ALB health checks and CloudWatch periods. Use observed target state and the metric dimensions as evidence. A missing dimension may leave the alarm showing `OK` when `treat_missing_data=notBreaching`; alarm state alone does not prove the application is healthy. This exercise does **not** deliver a notification.

## Recover and restore the one-instance baseline

Restore the stopped service and confirm both targets are healthy:

```bash
scripts/incident.sh 03 reset
scripts/validate-baseline.sh
```

The alarm is Terraform-managed. The `08 reset` action deliberately will not overwrite its state. Restore only the alarm after reviewing its plan:

```bash
terraform -chdir=terraform plan -target='aws_cloudwatch_metric_alarm.alb_5xx[0]' -out=incident-08-alarm-reset.tfplan
# Apply ONLY if the planned modification is the intended alarm correction.
terraform -chdir=terraform apply incident-08-alarm-reset.tfplan
scripts/incident.sh 08 status
```

Remove `shop_desired_capacity = 2` from `terraform/terraform.tfvars` (or set it back to `1`). Then review and apply the scale-down plan:

```bash
terraform -chdir=terraform plan -out=incident-08-scale-down.tfplan
terraform -chdir=terraform apply incident-08-scale-down.tfplan
scripts/validate-baseline.sh
terraform -chdir=terraform plan
```

Verify that exactly one target is healthy after scale-down and that the final Terraform plan has no unexpected changes. If any step fails, preserve the evidence and inspect the actual resources before proceeding. **Do not destroy the shared Shop environment while investigating.**
