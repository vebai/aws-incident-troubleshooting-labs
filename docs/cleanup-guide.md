# Remove practice AWS resources

Run these steps **from your computer**, using the same AWS account, Region and Terraform state you used for setup.

1. Undo incident changes using each incident guide. For Incident 07, use `terraform -chdir=labs/incident-07/terraform destroy` before removing shared networking.
2. Remove the independent Incident 01 and Incident 09 CloudFormation stacks using their incident guides. Wait for deletion completion.
3. From the repository root, run `terraform -chdir=terraform plan -destroy` and check the planned removals. Then run `terraform -chdir=terraform destroy`.
4. If Terraform cannot delete the S3 bucket because it contains object versions or delete markers, inspect the **exact** bucket name using `terraform -chdir=terraform output -raw bucket`. In the S3 Console, open that bucket, choose **Empty**, confirm that *all versions and delete markers* are included, and verify the bucket is empty. This is irreversible and must be performed only on the named lab bucket. Retry Terraform destroy afterwards.
5. Check AWS EC2 instances, Auto Scaling groups, load balancers, target groups, VPC, CloudWatch alarms, CloudFormation stacks and S3 buckets for residual lab resources. Look in the correct AWS Region.

**Keep your Terraform state until the resources are actually gone.** Losing state does not delete AWS infrastructure. See [Lost Terraform state](LOST_TERRAFORM_STATE_CLEANUP.md) if you cannot find it. Do not use `terraform state rm` as a cleanup substitute.
