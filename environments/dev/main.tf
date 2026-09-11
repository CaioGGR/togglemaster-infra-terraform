# ==============================================================================
# AMBIENTE DEV - INFRAESTRUTURA PRINCIPAL
# Orquestra a chamada dos módulos reutilizáveis para o ambiente de desenvolvimento
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Módulo de Rede (VPC, Subnets, Internet Gateway, NAT Gateway)
# ------------------------------------------------------------------------------
# Cria a infraestrutura de rede isolada em 2 AZs (us-east-1a e us-east-1b)
# pronta com as tags para o AWS Load Balancer Controller do EKS.
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  # vpc_cidr e as faixas de subnets utilizam os valores padrão definidos no módulo (10.0.0.0/16)
}

# ------------------------------------------------------------------------------
# 2. Módulo de Serviços Base (Amazon ECR e Amazon SQS)
# ------------------------------------------------------------------------------
# Cria os repositórios Docker privados para os 5 microsserviços (com scan e lifecycle)
# e a fila SQS para mensageria assíncrona com Long Polling.
module "services_base" {
  source = "../../modules/services_base"

  project_name = var.project_name
  environment  = var.environment
}

# ------------------------------------------------------------------------------
# 3. Módulo de Banco de Dados (RDS PostgreSQL, ElastiCache Redis e DynamoDB)
# ------------------------------------------------------------------------------
# Camada de persistência poliglota:
# - Recebe vpc_id e private_subnet_ids diretamente do módulo VPC
# - 3 instâncias isoladas PostgreSQL (auth, flag, targeting)
# - 1 nó Redis em memória para cache do evaluation
# - 1 tabela DynamoDB para eventos do analytics
module "database" {
  source = "../../modules/database"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_password        = var.db_password
}
