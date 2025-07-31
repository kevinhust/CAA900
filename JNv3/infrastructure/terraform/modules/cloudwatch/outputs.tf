# CloudWatch Module Outputs

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "log_group_names" {
  description = "Names of CloudWatch log groups created"
  value = var.create_log_groups ? [
    aws_cloudwatch_log_group.application_logs[0].name
  ] : []
}

output "alarm_names" {
  description = "Names of CloudWatch alarms created"
  value = [
    aws_cloudwatch_metric_alarm.database_connections_high.alarm_name
  ]
}