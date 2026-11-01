# Incident 09 — The Rollback That Hid the Cause

**Optional exercise.** A stack update does not complete as intended. The book provides the investigation; this page provides only the controls and safe exit.

**Requires:** Shared Shop VPC and working AWS account. The test creates its own CloudFormation stack, not a new Shop application.

```bash
# Confirm the Shop works and allow lab changes.
scripts/validate-baseline.sh
export CONFIRM_LAB_CHANGES=YES
# Create and inspect the separate stack.
scripts/incident.sh 09 setup
aws cloudformation describe-stacks --stack-name shop-rollback-lab --query 'Stacks[0].StackStatus' --output text
# Trigger the update experiment and read its initial state.
scripts/incident.sh 09 inject
scripts/incident.sh 09 status
```

**Stop and investigate:** Follow Incident 09 in the book. An update request can return before the operation finishes.

**Safe cleanup:** Wait until the stack reaches a completed state (normally `UPDATE_ROLLBACK_COMPLETE`) before deleting it. If it shows `UPDATE_ROLLBACK_FAILED`, stop and inspect AWS events rather than forcing deletion.

```bash
# Delete only this separate test stack.
scripts/incident.sh 09 cleanup
aws cloudformation wait stack-delete-complete --stack-name shop-rollback-lab
scripts/validate-baseline.sh
```
