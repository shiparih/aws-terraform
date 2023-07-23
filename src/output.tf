# output "cluster_id" {
#   value       = aws_elasticache_cluster.redis_cluster.id
#   description = "Redis primary endpoint"
# }


output "lambda" {
  value = aws_lambda_function.lambda_function.qualified_arn
}