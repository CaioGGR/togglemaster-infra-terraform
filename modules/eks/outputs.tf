# ==============================================================================
# OUTPUTS DO MÓDULO EKS
# Exporta informações essenciais para autenticação e conexão com o cluster Kubernetes
# ==============================================================================

output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "Nome do Cluster EKS (usado pelo comando 'aws eks update-kubeconfig' para conectar o kubectl)"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "Endpoint HTTPS da API do Kubernetes (API Server do Control Plane)"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "Certificado CA codificado em Base64 para autenticação segura via kubectl/Helm"
}

output "cluster_security_group_id" {
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description = "ID do Security Group principal criado automaticamente pelo EKS para o cluster"
}
