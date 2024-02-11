output "password" {
  value = random_string.password.result
}

output "address" {
  value = var.use_aurora ? aws_rds_cluster.cluster[0].endpoint : aws_db_instance.instance[0].address
}

output "arn" {
  value = var.use_aurora ? aws_rds_cluster.cluster[0].arn : aws_db_instance.instance[0].arn
}

output "username" {
  value = var.username
}

output "address_alias" {
  value = aws_route53_record.db_record.fqdn
}
