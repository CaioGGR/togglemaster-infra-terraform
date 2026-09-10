# ==============================================================================
# VARIÁVEIS DO MÓDULO VPC
# Define os parâmetros de rede e subnets para o cluster EKS e serviços
# ==============================================================================

variable "project_name" {
  type        = string
  description = "Nome base do projeto (usado como prefixo na nomenclatura dos recursos)"
}

variable "environment" {
  type        = string
  description = "Ambiente de implantação (ex: dev, prod, staging)"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Faixa de IPs principal da rede VPC (permite até 65.536 endereços)"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "Zonas de disponibilidade da AWS para distribuir as subnets (mínimo 2 para alta disponibilidade e EKS)"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "Blocos de IPs das subnets públicas (onde ficam Internet Gateway e Load Balancers externos)"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
  description = "Blocos de IPs das subnets privadas (onde rodam os Nodes do EKS, RDS e Redis sem IP público)"
}
