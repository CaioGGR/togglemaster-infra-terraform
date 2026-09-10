# ==============================================================================
# BOOTSTRAP DO BACKEND REMOTO (S3 + DYNAMODB)
# Objetivo: Criar a infraestrutura necessária para armazenar o arquivo de estado
# (terraform.tfstate) dos ambientes de forma remota, segura e com bloqueio concorrente.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configuração do provedor AWS com a região onde os recursos serão criados
provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# VARIÁVEIS
# ------------------------------------------------------------------------------
variable "aws_region" {
  description = "Região da AWS para provisionamento do bucket e da tabela"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo identificador do projeto para nomenclatura dos recursos"
  type        = string
  default     = "togglemaster"
}

# ------------------------------------------------------------------------------
# RECURSOS DE SUPORTE
# ------------------------------------------------------------------------------
# Gera um sufixo aleatório em letras minúsculas.
# Motivo: Nomes de buckets S3 são globais na AWS e não podem colidir com outros existentes.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ------------------------------------------------------------------------------
# 1. BUCKET S3 (Armazenamento do State)
# ------------------------------------------------------------------------------
# Bucket S3 que armazenará os arquivos terraform.tfstate dos projetos.
# force_destroy = false impede exclusão acidental caso ainda existam arquivos de estado nele.
resource "aws_s3_bucket" "state_bucket" {
  bucket        = "${var.project_name}-tfstate-${random_string.suffix.result}"
  force_destroy = false

  tags = {
    Name        = "Terraform State Storage"
    Environment = "Bootstrap"
  }
}

# Versionamento: guarda o histórico de alterações do tfstate a cada 'apply'.
# Permite restaurar uma versão anterior em caso de corrupção ou exclusão acidental.
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia em repouso (SSE-S3 com algoritmo AES256).
# Garante que credenciais e dados sensíveis mapeados no estado fiquem protegidos no disco da AWS.
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloqueio de acesso público total ao Bucket.
# Prática essencial de segurança: impede que o estado da infraestrutura fique exposto à internet.
resource "aws_s3_bucket_public_access_block" "state_public_block" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 2. TABELA DYNAMODB (State Locking / Trava de Concorrência)
# ------------------------------------------------------------------------------
# Tabela usada pelo Terraform para criar travas automáticas durante execuções.
# Impede que múltiplos desenvolvedores ou pipelines façam 'apply' simultâneo e corrompam o estado.
# O Terraform exige obrigatoriamente a chave primária (hash_key) nomeada como "LockID".
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST" # Modo sob demanda: sem custo fixo, cobra centavos apenas por leitura/escrita
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S" # Tipo String (exigido pelo backend S3 do Terraform)
  }

  tags = {
    Name    = "Terraform State Lock Table"
    Purpose = "Terraform State Lock"
  }
}

# ------------------------------------------------------------------------------
# OUTPUTS
# ------------------------------------------------------------------------------
# Exibe no terminal os nomes gerados após o 'terraform apply'.
# Você usará esses valores para preencher o 'backend.tf' de cada ambiente (ex: dev, prod).
output "s3_bucket_name" {
  value       = aws_s3_bucket.state_bucket.id
  description = "Nome único do Bucket S3 gerado" # copie para o backend.tf
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "Nome da tabela DynamoDB de lock" # copie para o backend.tf
}
