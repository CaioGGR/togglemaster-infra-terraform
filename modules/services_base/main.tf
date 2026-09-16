# ==============================================================================
# MÓDULO SERVICES_BASE - RECURSOS DE SUPORTE ÀS APLICAÇÕES
# Cria os registros de containers (Amazon ECR) para os microsserviços
# e a fila de mensageria assíncrona (Amazon SQS).
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Repositórios no Amazon ECR
# ------------------------------------------------------------------------------
# Cria um repositório Docker privado no ECR para cada um dos 5 microsserviços.
# MUTABLE permite sobrescrever tags como ':latest' durante deploys de desenvolvimento.
# scan_on_push ativa a análise automática de vulnerabilidades de segurança (CVEs) em cada push.
resource "aws_ecr_repository" "services" {
  for_each             = toset(var.service_names)
  name                 = "${var.project_name}-${each.value}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Permite exclusão pelo terraform destroy mesmo contendo imagens Docker

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-${each.value}-ecr"
    Service = each.value
  }
}

# Política de ciclo de vida (Lifecycle Policy) do ECR.
# Mantém no máximo as últimas 10 imagens por repositório e expira as mais antigas.
# Evita acúmulo desnecessário de gigabytes de imagens e estouro de cota/créditos na AWS.
resource "aws_ecr_lifecycle_policy" "services_policy" {
  for_each   = toset(var.service_names)
  repository = aws_ecr_repository.services[each.value].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Manter apenas as últimas 10 imagens"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 2. Fila SQS (Mensageria Assíncrona)
# ------------------------------------------------------------------------------
# Fila padrão para comunicação desacoplada entre os microsserviços (ex: envio de eventos de auditoria e analytics).
# Long polling (receive_wait_time_seconds = 10) mantém a conexão aberta esperando mensagens,
# reduzindo drasticamente o número de chamadas de API vazias e os custos na AWS.
resource "aws_sqs_queue" "events" {
  name                      = "${var.project_name}-events-queue-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB (tamanho máximo padrão de mensagem SQS)
  message_retention_seconds = 86400  # 1 dia de retenção de mensagens na fila
  receive_wait_time_seconds = 10     # Long polling ativado

  tags = {
    Name = "${var.project_name}-events-queue-${var.environment}"
  }
}
