# Lab scope and limitations

These optional exercises require a dedicated AWS sandbox, suitable permissions and sufficient service quotas. AWS services, account defaults and console navigation can change; inspect each plan and API response before taking action.

- Incident 01 is a caller Region mismatch, not an infrastructure failure.
- Incident 04 uses an EC2 host firewall rule rather than an AWS security-group edit.
- Incident 05 demonstrates an ALB health-check mismatch; application requests may still succeed through ALB fail-open behaviour.
- Incident 07 isolates an S3 bootstrap dependency in a one-instance ASG. It does not attach to an ALB or demonstrate repeated Auto Scaling replacement.
- Incident 08 removes the `LoadBalancer` dimension from a genuine `UnHealthyHostCount` alarm, not notification delivery. The shared baseline has one target; the book illustrates two.
- Incident 09 demonstrates a failed CloudFormation update and rollback in a separate stack; the stack requires the shared VPC.
- Incident 10 combines three individual faults and requires manual, staged verification and recovery.

Use real observations to judge success. Do not assume resource health implies customer-facing function or that an `OK` alarm proves the right metric is being observed.
