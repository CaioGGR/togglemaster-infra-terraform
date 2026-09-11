# ==============================================================================
# MÓDULO DATABASE - CAMADA DE PERSISTÊNCIA POLIGLOTA
# Provisiona a camada de dados dos microsserviços:
# 1. Três instâncias RDS PostgreSQL (auth, flag, targeting)
# 2. Um cluster ElastiCache Redis para cache em memória (evaluation)
# 3. Uma tabela DynamoDB NoSQL para eventos de telemetria (analytics)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Security Groups (Controle de Acesso à Camada de Dados)
# ------------------------------------------------------------------------------
# Libera acesso à porta 5432 (PostgreSQL) exclusivamente para recursos dentro da VPC
resource "aws_security_group" "postgres_sg" {
  name        = "${var.project_name}-postgres-sg-${var.environment}"
  description = "Permite trafego PostgreSQL interno da VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "Acesso PostgreSQL apenas da rede interna"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-postgres-sg-${var.environment}"
  }
}

# Libera acesso à porta 6379 (Redis) exclusivamente para recursos dentro da VPC
resource "aws_security_group" "redis_sg" {
  name        = "${var.project_name}-redis-sg-${var.environment}"
  description = "Permite trafego Redis interno da VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "Acesso Redis apenas da rede interna"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-redis-sg-${var.environment}"
  }
}

# ------------------------------------------------------------------------------
# 2. Subnet Groups (Alocação em Subnets Privadas Multi-AZ)
# ------------------------------------------------------------------------------
# Garante que os bancos PostgreSQL fiquem alocados em subnets privadas protegidas
resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-rds-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-rds-subnet-group-${var.environment}"
  }
}

# Agrupa as subnets privadas para o nó do ElastiCache Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-redis-subnet-group-${var.environment}"
  }
}

# ------------------------------------------------------------------------------
# 3. Provisionamento RDS PostgreSQL (Padrão Database-per-Service)
# ------------------------------------------------------------------------------
# Mapeia cada microsserviço com o nome exato do banco de dados esperado pelo backend
locals {
  postgres_databases = {
    auth      = "auth_db"
    flag      = "flags_db"
    targeting = "targeting_db"
  }
}

# Cria 3 instâncias independentes de banco PostgreSQL para manter o desacoplamento de microsserviços.
# skip_final_snapshot = true é essencial para que o 'terraform destroy' não trave no Lab.
# publicly_accessible = false garante que os bancos nunca tenham IP público na internet.
resource "aws_db_instance" "postgres" {
  for_each               = local.postgres_databases
  identifier             = "${var.project_name}-${each.key}-db-${var.environment}"
  engine                 = "postgres"
  engine_version         = "15.13"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20 # 20 GB (mínimo suportado pelo RDS)
  max_allocated_storage  = 50 # Auto-scaling de disco até 50 GB se necessário
  db_name                = each.value
  username               = "postgres"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name    = "${var.project_name}-${each.key}-db-${var.environment}"
    Service = each.key
  }
}

# ------------------------------------------------------------------------------
# 4. Cluster ElastiCache Redis (Cache em Memória)
# ------------------------------------------------------------------------------
# Utilizado pelo evaluation-service para leitura em milissegundos das feature flags ativas.
# Configurado com 1 nó 'cache.t3.micro' para otimização de custos de laboratório.
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-redis-${var.environment}"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  tags = {
    Name = "${var.project_name}-redis-${var.environment}"
  }
}

# ------------------------------------------------------------------------------
# 5. Tabela DynamoDB (Armazenamento NoSQL de Eventos)
# ------------------------------------------------------------------------------
# Utilizada pelo analytics-service para gravar métricas e logs de avaliação de flags.
# Modo PAY_PER_REQUEST (sob demanda): sem custo fixo, cobra centavos apenas pelas operações.
resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id" # Partition Key exigida pelo worker de analytics

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = {
    Name    = "ToggleMasterAnalytics"
    Service = "analytics"
  }
}
