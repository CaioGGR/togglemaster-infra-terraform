# ==============================================================================
# MÓDULO VPC - REDE E CONECTIVIDADE
# Cria a infraestrutura de rede isolada com subnets públicas e privadas,
# preparada para receber o cluster Kubernetes (EKS) e os bancos de dados.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. VPC Principal
# ------------------------------------------------------------------------------
# Cria a nuvem privada virtual isolada.
# enable_dns_hostnames e enable_dns_support são obrigatórios para o EKS resolver nomes internos.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

# ------------------------------------------------------------------------------
# 2. Internet Gateway (IGW)
# ------------------------------------------------------------------------------
# Ponto de entrada e saída direta da internet para a VPC (usado pelas subnets públicas).
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
  }
}

# ------------------------------------------------------------------------------
# 3. Subnets Públicas
# ------------------------------------------------------------------------------
# Onde ficam os Load Balancers voltados para a internet.
# As tags especiais 'kubernetes.io/role/elb = 1' são exigidas pela AWS para que o
# AWS Load Balancer Controller do EKS descubra automaticamente onde criar os Ingress/ALBs públicos.
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Atribui IP público automaticamente aos recursos desta subnet

  tags = {
    Name                                                                   = "${var.project_name}-public-subnet-${count.index + 1}-${var.environment}"
    "kubernetes.io/role/elb"                                               = "1" # Tag exigida pelo EKS para Load Balancers públicos
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-cluster" = "shared"
  }
}

# ------------------------------------------------------------------------------
# 4. Subnets Privadas
# ------------------------------------------------------------------------------
# Onde rodam as aplicações reais: Nós do EKS, instâncias de banco (RDS) e cache (Redis).
# Não possuem IP público nem recebem tráfego direto da internet.
# A tag 'kubernetes.io/role/internal-elb = 1' indica onde criar Load Balancers internos.
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                                                   = "${var.project_name}-private-subnet-${count.index + 1}-${var.environment}"
    "kubernetes.io/role/internal-elb"                                      = "1" # Tag exigida pelo EKS para Load Balancers internos
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-cluster" = "shared"
  }
}

# ------------------------------------------------------------------------------
# 5. Elastic IP e NAT Gateway
# ------------------------------------------------------------------------------
# O NAT Gateway fica em uma subnet pública e permite que os recursos da subnet privada
# (como nós do EKS baixando pacotes ou imagens) acessem a internet, mas impede que
# computadores da internet iniciem conexões diretas até as instâncias privadas.
# Usamos apenas 1 NAT Gateway para economizar custos no ambiente de laboratório/AWS Academy.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${var.environment}"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Alocado na primeira subnet pública

  tags = {
    Name = "${var.project_name}-nat-gw-${var.environment}"
  }

  depends_on = [aws_internet_gateway.gw]
}

# ------------------------------------------------------------------------------
# 6. Tabelas de Roteamento (Route Tables)
# ------------------------------------------------------------------------------
# Rota Pública: Todo o tráfego de saída desconhecido (0.0.0.0/0) vai para o Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
  }
}

# Rota Privada: Todo o tráfego de saída para a internet (0.0.0.0/0) passa pelo NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.environment}"
  }
}

# ------------------------------------------------------------------------------
# 7. Associação das Subnets às Tabelas de Rotas
# ------------------------------------------------------------------------------
# Conecta as subnets públicas à tabela pública
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Conecta as subnets privadas à tabela privada
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
