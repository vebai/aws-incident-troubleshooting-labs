#!/usr/bin/env bash
set -euo pipefail
 : "${AWS_PROFILE:?Set AWS_PROFILE to your AWS sandbox profile before running this historical inventory}"
export AWS_DEFAULT_REGION=eu-west-2
# This script examines one historical lab deployment; it is NOT a general cleanup tool.
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [[ "$ACCOUNT" != '760208981862' ]]; then echo "STOP: unexpected AWS account $ACCOUNT" >&2; exit 1; fi
echo "READ-ONLY inventory; account $ACCOUNT, Region eu-west-2"
echo '=== Auto Scaling ==='
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?starts_with(AutoScalingGroupName, `shop-incident-lab-f8caff`) || starts_with(AutoScalingGroupName, `shop-incident-07`)].[AutoScalingGroupName,MinSize,DesiredCapacity,MaxSize]' --output table
echo '=== EC2 instances ==='
aws ec2 describe-instances --filters 'Name=tag:Name,Values=shop-incident-lab-f8caff*,shop-incident-07*' --query 'Reservations[].Instances[].[InstanceId,State.Name,VpcId,Tags[?Key==`Name`]|[0].Value]' --output table
echo '=== Load balancers ==='
aws elbv2 describe-load-balancers --query 'LoadBalancers[?starts_with(LoadBalancerName, `shop-incident-lab-f8caff`)].[LoadBalancerName,LoadBalancerArn,State.Code]' --output table
echo '=== Target groups ==='
aws elbv2 describe-target-groups --query 'TargetGroups[?starts_with(TargetGroupName, `shop-incident-lab-f8caff`)].[TargetGroupName,TargetGroupArn]' --output table
echo '=== VPCs ==='
aws ec2 describe-vpcs --filters 'Name=tag:Name,Values=shop-incident-lab-f8caff*' --query 'Vpcs[].[VpcId,CidrBlock]' --output table
echo '=== Launch templates ==='
aws ec2 describe-launch-templates --query 'LaunchTemplates[?starts_with(LaunchTemplateName, `shop-incident-lab-f8caff`) || starts_with(LaunchTemplateName, `shop-incident-07`)].[LaunchTemplateId,LaunchTemplateName]' --output table
echo '=== CloudWatch alarms ==='
aws cloudwatch describe-alarms --alarm-name-prefix shop-incident-lab-f8caff --query 'MetricAlarms[].[AlarmName,StateValue]' --output table
echo '=== S3 buckets (matching exact lab prefix) ==='
aws s3api list-buckets --query 'Buckets[?starts_with(Name, `shop-incident-lab-f8caff`)].Name' --output table
echo '=== IAM roles ==='
aws iam list-roles --query 'Roles[?starts_with(RoleName, `shop-incident-lab-f8caff`) || starts_with(RoleName, `shop-incident-07`)].RoleName' --output table
echo '=== CloudFormation stacks ==='
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE DELETE_FAILED --query 'StackSummaries[?starts_with(StackName, `shop-`) ].[StackName,StackStatus]' --output table
echo 'No resources were changed.'
