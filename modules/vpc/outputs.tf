# ==============================================================================
# OUTPUTS DO MÓDULO VPC
# Exporta os identificadores gerados para serem consumidos pelos outros módulos (EKS, RDS)
# ==============================================================================

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID único da VPC criada (usado por Security Groups e pelo cluster EKS)"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Lista com os IDs das subnets públicas (onde ficam os Load Balancers externos)"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Lista com os IDs das subnets privadas (onde os Nodes do EKS e bancos são provisionados)"
}
