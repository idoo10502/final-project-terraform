# שם השירות, כדי שהקוד הראשי יוכל להשתמש בו
output "service_name" {
  value = aws_ecs_service.this.name
}

# הכתובת של תבנית המשימה
output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

# שם קבוצת הלוגים, כדי לדעת איפה לחפש
output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}
