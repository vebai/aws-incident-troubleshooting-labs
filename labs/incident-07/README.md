# Incident 07 — The Launch That Never Finished

**Optional exercise.** A separate EC2 instance starts but does not complete setup. The book explains how to investigate the evidence; these commands simply create and reset the experiment.

**Requires:** The shared Shop network, S3 bucket, and an AWS practice account. The extra Auto Scaling group can launch **one billable instance**. It is separate from the main Shop Auto Scaling group and is **not connected to its load balancer**.

From the repository root, generate a **private** Terraform settings file using the shared environment you already created:

```bash
export CONFIRM_LAB_CHANGES=YES
scripts/prepare-incident-07.sh
cat labs/incident-07/terraform/terraform.tfvars
```

The helper reads your current Terraform outputs, Auto Scaling group and launch template to locate the VPC, subnet, security group, machine image and S3 bucket. **Check the resulting values** before proceeding. The file is excluded from Git. You can also create it manually if you need a different subnet or image.

```bash
# Initialise, validate and preview only the separate test instance.
terraform -chdir=labs/incident-07/terraform init
terraform -chdir=labs/incident-07/terraform validate
terraform -chdir=labs/incident-07/terraform plan -out=incident-07.tfplan
# Review the plan, then start this isolated experiment.
terraform -chdir=labs/incident-07/terraform apply incident-07.tfplan
terraform -chdir=labs/incident-07/terraform output
```

**Stop and investigate:** Use Incident 07 in the book. Locate the isolated instance under the dedicated Auto Scaling group, connect by Session Manager, and capture its initial setup status. This experiment tests a setup dependency rather than the full Shop / ALB scenario.

**Safe reset:** To test a corrected configuration, set `inject_failure = false` in the same private variables file, review a new plan and apply it. After the test, **destroy the isolated module only**:

```bash
# Preview and apply the isolated correction, if desired.
terraform -chdir=labs/incident-07/terraform plan -out=incident-07-reset.tfplan
terraform -chdir=labs/incident-07/terraform apply incident-07-reset.tfplan
# Remove the isolated test resources when finished.
terraform -chdir=labs/incident-07/terraform destroy
```

Inspect the destroy plan and confirm that it affects **only this isolated lab**. Do not destroy the main Shop environment until all other exercises are finished.
