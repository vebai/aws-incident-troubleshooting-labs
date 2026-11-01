# Lab operating method

1. Establish the AWS account, identity and Region.
2. Verify the healthy application through the ALB and record evidence.
3. Introduce **one** controlled fault, only in a sandbox.
4. Stop using implementation code as a diagnostic hint; use the book's EVIDENCE investigation.
5. Preserve observations and make the smallest supported repair.
6. Prove the original failing workflow has recovered.
7. Reset or destroy lab resources; inspect retained resources and costs.

**Limitations:** The incident scripts are untested candidate implementations. Chapter 7/Incident 07 and Incident 10 injection are disabled. Shell `setup` checks for incidents 02–08 require the shared Terraform stack. Incident 01 is independent and uses its own script.

## Confirm a Systems Manager command finished

If a script prints a command ID after starting or stopping the service, inspect the result (run from your local shell):

```bash
aws ssm get-command-invocation --command-id COMMAND_ID --instance-id INSTANCE_ID --query '{Status:Status,Output:StandardOutputContent,Error:StandardErrorContent}' --output json
```

Get `INSTANCE_ID` from `scripts/show-resources.sh` or the EC2 Console. Replace both placeholders. `Success` confirms the remote command ran; inspect its output before assuming the service or firewall is in the intended state.
