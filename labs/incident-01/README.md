# Incident 01 — The Missing Stack

**Optional standalone exercise.** Investigate a CloudFormation stack that appears missing because the investigator is using the wrong AWS Region. No shared Shop infrastructure or Terraform state is required.

**Requires:** AWS CLI, a dedicated AWS sandbox, and CloudFormation permissions. From the repository root, confirm the AWS account and choose the stack's deployment Region (default: `eu-west-2`).

```bash
aws sts get-caller-identity
export LAB_REGION=eu-west-2
export CONFIRM_LAB_CHANGES=YES
scripts/incident.sh 01 setup
scripts/incident.sh 01 status
```

**Stop and investigate:** Follow Incident 01 in the book. Query `shop-context-lab` without `--region` from a shell configured for a *different* Region, then explicitly query the correct `LAB_REGION`. This exercise changes caller context, not infrastructure. The book's `shop-baseline` is an illustrative stack name; the live lab uses `shop-context-lab`.

**Safe cleanup:** Delete only the standalone laboratory stack in the Region where you created it:

```bash
scripts/incident.sh 01 cleanup
aws cloudformation wait stack-delete-complete --stack-name shop-context-lab --region "$LAB_REGION"
```

If the initial query seems to show an absent stack, inspect the actual account, active identity, Region and stack name before concluding deletion occurred.
