# Clean up an AWS lab when Terraform state has been lost

**Do not run `terraform destroy` from a freshly extracted repository.** Its state is empty and it cannot identify previously created infrastructure. Re-running `terraform apply` would create a second infrastructure deployment.

Each Shop deployment receives a generated resource prefix and account-specific identifiers. If Terraform state is lost, first verify your active AWS account and Region, then run `scripts/inventory-lost-state.sh` to inventory possible remaining resources. Confirm ownership using resource names, tags, identifiers and deployment records before planning any deletion. Save the inventory output privately. The inventory script is read-only.

To delete resources, use the AWS Console (EC2 Auto Scaling Groups, Load Balancers, Target Groups, Launch Templates, Security Groups, VPC, CloudWatch Alarms, S3, IAM) or a separately reviewed resource-specific cleanup plan. Delete Auto Scaling group before its launch template; ALB/listener before target group; dependencies before VPC and subnets. For a versioned S3 bucket, remove all object versions and delete markers before deleting the bucket. Verify the exact account, Region and tags for each deletion. Do not delete shared or unrelated resources. Do not commit inventory output, state files, plans, or secrets.
