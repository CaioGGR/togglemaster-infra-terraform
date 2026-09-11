# ==============================================================================
# OUTPUTS DO AMBIENTE DEV
# Exibe os principais dados e endpoints gerados pelos módulos
# ==============================================================================

# --- Rede (VPC) ---
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID da VPC de desenvolvimento criada"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs das subnets públicas (Load Balancers externos)"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "IDs das subnets privadas (onde rodam os Nodes do EKS e bancos)"
}

# --- Serviços Base (ECR & SQS) ---
output "ecr_repository_urls" {
  value       = module.services_base.ecr_repository_urls
  description = "Mapa com as URLs dos repositórios ECR para cada microsserviço"
}

output "sqs_queue_url" {
  value       = module.services_base.sqs_queue_url
  description = "URL da fila SQS para envio e consumo de eventos"
}

# --- Banco de Dados (RDS, Redis, DynamoDB) ---
output "rds_endpoints" {
  value       = module.database.rds_endpoints
  description = "Endpoints de conexão com host e porta dos 3 bancos PostgreSQL"
}

output "database_urls" {
  value       = module.database.database_urls
  description = "URIs completas de conexão PostgreSQL (DATABASE_URL) formatadas por serviço"
  sensitive   = true
}

output "redis_endpoint" {
  value       = module.database.redis_endpoint
  description = "Hostname/endpoint do cluster Redis"
}

output "redis_url" {
  value       = module.database.redis_url
  description = "URL do Redis formatada para a variável REDIS_URL do evaluation-service"
}

output "analytics_dynamodb_table" {
  value       = module.database.dynamodb_table_name
  description = "Nome da tabela DynamoDB de analytics"
}
