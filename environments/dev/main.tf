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
