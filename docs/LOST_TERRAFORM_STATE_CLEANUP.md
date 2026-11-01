# Clean up an AWS lab when Terraform state has been lost

**Do not run `terraform destroy` from a freshly extracted repository.** Its state is empty and it cannot identify previously created infrastructure. Re-running `terraform apply` would create a second infrastructure deployment.

The tested shared Shop baseline is identified by the prefix `shop-incident-lab-f8caff` in account `760208981862`, Region `eu-west-2`. First use `scripts/inventory-lost-state.sh` to list actual resources, confirm their exact identifiers, and save the output privately. The inventory script is read-only.

To delete resources, use the AWS Console (EC2 Auto Scaling Groups, Load Balancers, Target Groups, Launch Templates, Security Groups, VPC, CloudWatch Alarms, S3, IAM) or a separately reviewed resource-specific cleanup plan. Delete Auto Scaling group before its launch template; ALB/listener before target group; dependencies before VPC and subnets. For a versioned S3 bucket, remove all object versions and delete markers before deleting the bucket. Verify the exact account, Region and tags for each deletion. Do not delete shared or unrelated resources. Do not commit inventory output, state files, plans, or secrets.

Separate Incident 7 resources were destroyed and Incident 9's stack deletion waiter succeeded during live validation. Recheck for stragglers. The main Shop baseline remained running at last check and may incur charges.
