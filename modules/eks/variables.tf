# ==============================================================================
# VARIÁVEIS DO MÓDULO EKS
# Define os parâmetros de configuração do Cluster Kubernetes e dos Worker Nodes
# ==============================================================================

variable "project_name" {
  type        = string
  description = "Nome base do projeto (usado como prefixo na nomenclatura dos recursos do EKS)"
}

variable "environment" {
  type        = string
  description = "Ambiente de implantação (ex: dev, prod)"
}

variable "vpc_id" {
  type        = string
  description = "ID da VPC onde o Security Group do cluster será criado"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Lista de IDs das subnets privadas onde o EKS e os Worker Nodes serão provisionados"
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "Tipo de instância EC2 para os Worker Nodes (t3.medium possui 2 vCPUs e 4GB RAM, ideal para os 5 microsserviços + ArgoCD)"
}
