# ==============================================================================
# OUTPUTS DO MÓDULO SERVICES_BASE
# Exporta as URLs do ECR e os identificadores da fila SQS
# ==============================================================================

output "ecr_repository_urls" {
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
  description = "Mapa com as URLs dos repositórios ECR para cada microsserviço (usadas pelas pipelines de CI/CD para fazer docker push)"
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.events.url
  description = "URL da fila SQS para envio e consumo de mensagens"
}

output "sqs_queue_arn" {
  value       = aws_sqs_queue.events.arn
  description = "ARN da fila SQS (usado para configurar permissões de IAM para os pods do Kubernetes)"
}
