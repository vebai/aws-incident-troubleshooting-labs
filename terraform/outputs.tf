output "alb_url" {
 value = "http://${aws_lb.shop.dns_name}" 
}

output "alb_dns_name" {
 value = aws_lb.shop.dns_name 
}

output "asg_name" {
 value = aws_autoscaling_group.shop.name 
}

output "target_group_arn" {
 value = aws_lb_target_group.shop.arn 
}

output "launch_template_id" {
 value = aws_launch_template.shop.id 
}

output "vpc_id" {
 value = aws_vpc.shop.id 
}

output "bucket" {
 value = aws_s3_bucket.catalog.bucket 
}

output "instance_role" {
 value = aws_iam_role.app.name 
}

output "app_security_group_id" {
 value = aws_security_group.app.id 
}

output "alb_security_group_id" {
 value = aws_security_group.alb.id 
}

output "alarm_name" {
 value = var.enable_alarm ? aws_cloudwatch_metric_alarm.alb_5xx[0].alarm_name : "" 
}

output "region" {
 value = var.aws_region 
}

