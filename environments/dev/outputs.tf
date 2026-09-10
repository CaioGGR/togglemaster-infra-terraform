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
