# Lab operating method

1. Establish the AWS account, identity and Region.
2. Verify the healthy application through the ALB and record evidence.
3. Introduce **one** controlled fault, only in a sandbox.
4. Stop using implementation code as a diagnostic hint; use the book's EVIDENCE investigation.
5. Preserve observations and make the smallest supported repair.
6. Prove the original failing workflow has recovered.
7. Reset or destroy lab resources; inspect retained resources and costs.

**Limitations:** The incident scripts are candidate implementations pending live AWS validation. Incident 07 uses a separate Terraform exercise; Incident 10 has no single injection command and combines existing controls as an alternative scenario. Incident 01 runs independently of shared Terraform state. Incident 08 requires a temporary second Shop target for the book's two-target observation. Run `bash scripts/validate-all.sh` for read-only local source checks; static success does not establish live behaviour.

## Confirm a Systems Manager command finished

If a script prints a command ID after starting or stopping the service, inspect the result (run from your local shell):

```bash
aws ssm get-command-invocation --command-id COMMAND_ID --instance-id INSTANCE_ID --query '{Status:Status,Output:StandardOutputContent,Error:StandardErrorContent}' --output json
```

Get `INSTANCE_ID` from `scripts/show-resources.sh` or the EC2 Console. Replace both placeholders. `Success` confirms the remote command ran; inspect its output before assuming the service or firewall is in the intended state.
