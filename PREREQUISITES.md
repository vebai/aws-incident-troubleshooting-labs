# Prerequisites

- A dedicated AWS sandbox account; permission for VPC, EC2, ELBv2, Auto Scaling, IAM, SSM, S3, CloudFormation, CloudWatch and related `iam:PassRole` operations.
- AWS CLI v2 authenticated via a short-lived profile / IAM Identity Center where possible.
- Terraform 1.6+ installed locally; AWS provider installation requires internet access.
- 2 usable availability zones, EC2 `t3.micro` quota/capacity, public IP allocation, ALB capacity and Systems Manager agent connectivity in eu-west-2.
- macOS: Homebrew `brew install terraform awscli`; Linux: install Terraform from official HashiCorp repository and AWS CLI v2 from AWS documentation; verify `terraform version` and `aws --version`.
- Review public ingress CIDRs, costs, instance profiles and CloudFormation operations.
- Never use production credentials or environments.
