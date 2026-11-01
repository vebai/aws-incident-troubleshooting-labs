# Incident 01 — The Missing Stack

**Optional exercise.** An expected resource appears to be missing. The book provides the investigation; this page provides only the controls and safe exit.

**Requires:** AWS CLI and a practice account; the Shop environment is not needed. Run from the repository root.

```bash
# Create the small test stack in your chosen Region.
aws cloudformation deploy --stack-name shop-context-lab --template-file cloudformation/incident-01/context.yaml --region "$AWS_DEFAULT_REGION"
# Check the stack exists.
aws cloudformation describe-stacks --stack-name shop-context-lab --region "$AWS_DEFAULT_REGION" --query 'Stacks[0].StackStatus' --output text
# Explore the reported symptom using Incident 01 in the book.
```

**Stop and investigate.** Do not interpret the evidence here as an answer key.

**Safe cleanup:**

```bash
# Delete only this experiment's stack and confirm deletion.
aws cloudformation delete-stack --stack-name shop-context-lab --region "$AWS_DEFAULT_REGION"
aws cloudformation wait stack-delete-complete --stack-name shop-context-lab --region "$AWS_DEFAULT_REGION"
```
