# ==============================================================================
# VARIÁVEIS DO MÓDULO SERVICES_BASE
# Define os microsserviços e configurações de suporte (ECR e Mensageria)
# ==============================================================================

variable "project_name" {
  type        = string
  description = "Nome base do projeto (usado como prefixo nos repositórios e filas)"
}

variable "environment" {
  type        = string
  description = "Ambiente de implantação (ex: dev, prod)"
}

variable "service_names" {
  type        = list(string)
  default     = ["auth", "flag", "targeting", "evaluation", "analytics"]
  description = "Lista com os nomes dos 5 microsserviços que compõem o ecossistema ToggleMaster"
}
