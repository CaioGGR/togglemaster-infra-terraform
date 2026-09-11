variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto para padronizar os nomes dos recursos"
  type        = string
}

variable "environment" {
  description = "Identificador do ambiente de implantação"
  type        = string
  default     = "dev"
}

variable "db_password" {
  description = "Senha master para as instâncias RDS PostgreSQL"
  type        = string
  sensitive   = true
}
