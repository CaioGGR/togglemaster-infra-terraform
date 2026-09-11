# ==============================================================================
# OUTPUTS DO MÓDULO DATABASE
# Exporta endpoints e variáveis de conexão para injeção nos pods do Kubernetes (EKS)
# ==============================================================================

# Mapa com os endpoints brutos de cada banco PostgreSQL (host:porta)
output "rds_endpoints" {
  value       = { for k, v in aws_db_instance.postgres : k => v.endpoint }
  description = "Endpoints de conexão com host e porta dos 3 bancos PostgreSQL"
}

# Connection strings completas prontas para serem injetadas na variável DATABASE_URL dos pods
output "database_urls" {
  value = {
    for k, v in aws_db_instance.postgres : k => "postgres://postgres:${var.db_password}@${v.endpoint}/${local.postgres_databases[k]}"
  }
  description = "URIs completas de conexão PostgreSQL (DATABASE_URL) formatadas por serviço"
  sensitive   = true
}

# Endpoint do nó do ElastiCache Redis (acessando o primeiro nó [0] da lista)
output "redis_endpoint" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  description = "Hostname/endpoint do cluster Redis"
}

# URL completa formatada para a variável de ambiente REDIS_URL do evaluation-service
output "redis_url" {
  value       = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
  description = "URL do Redis pronta para a variável REDIS_URL do evaluation-service"
}

# Nome da tabela DynamoDB usada pelo worker de analytics
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.analytics.name
  description = "Nome da tabela DynamoDB para eventos do analytics-service"
}
