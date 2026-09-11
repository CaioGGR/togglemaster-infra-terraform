# ==============================================================================
# VARIÁVEIS DO MÓDULO DATABASE
# Define parâmetros para RDS PostgreSQL, ElastiCache Redis e DynamoDB
# ==============================================================================

variable "project_name" {
  type        = string
  description = "Nome base do projeto (usado como prefixo nos recursos)"
}

variable "environment" {
  type        = string
  description = "Ambiente de implantação (ex: dev, prod)"
}

variable "vpc_id" {
  type        = string
  description = "ID da VPC onde os Security Groups dos bancos serão criados"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Bloco CIDR da VPC permitido para conexão interna aos bancos"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Lista de IDs das subnets privadas para isolar os bancos sem acesso à internet"
}

variable "db_password" {
  type        = string
  description = "Senha master de administrador para as instâncias do RDS PostgreSQL"
  sensitive   = true
}
