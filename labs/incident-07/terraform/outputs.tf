output "isolated_asg_name" { value = aws_autoscaling_group.incident.name }
output "isolated_launch_template_id" { value = aws_launch_template.incident.id }
output "failure_mode" { value = var.inject_failure ? "incorrect S3 bootstrap key" : "correct S3 bootstrap key" }
