# ==============================================================================
# MÓDULO EKS - CLUSTER KUBERNETES GERENCIADO
# Provisiona o Control Plane do Amazon EKS e o Node Group (Worker Nodes)
# nas subnets privadas da VPC, compatível com as regras do AWS Academy LabRole.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. IAM Role do AWS Academy
# ------------------------------------------------------------------------------
# No AWS Academy Learner Lab, a criação de novas IAM Roles é bloqueada por SCP.
# Portanto, utilizamos a role pré-configurada 'LabRole', que já possui todas as
# permissões administrativas necessárias para o EKS e para os nós EC2.
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ------------------------------------------------------------------------------
# 2. Security Group do Control Plane do EKS
# ------------------------------------------------------------------------------
# Grupo de segurança adicional para o Control Plane do Kubernetes.
# Permite saída irrestrita para comunicação com os worker nodes e APIs da AWS.
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg-${var.environment}"
  description = "Security Group do Cluster EKS Control Plane"
  vpc_id      = var.vpc_id

  egress {
    description = "Permite saida irrestrita para comunicacao externa e com os nos"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-cluster-sg-${var.environment}"
  }
}

# ------------------------------------------------------------------------------
# 3. Cluster EKS (Control Plane)
# ------------------------------------------------------------------------------
# Provisiona o cérebro do Kubernetes gerenciado pela AWS (API Server, etcd, controllers).
# - endpoint_private_access: permite que os nós dentro da VPC falem com a API via IP privado.
# - endpoint_public_access: permite que você use o 'kubectl' do seu computador.
# - subnet_ids: aloca as interfaces de rede do EKS nas subnets privadas Multi-AZ.
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# ------------------------------------------------------------------------------
# 4. EKS Managed Node Group (Worker Nodes)
# ------------------------------------------------------------------------------
# Grupo gerenciado de instâncias EC2 onde os containers (Pods) dos microsserviços rodam.
# - Alocado exclusivamente nas subnets privadas (segurança: sem IP público na internet).
# - Instâncias 't3.medium' fornecem 2 vCPUs e 4GB RAM cada (ideal para os 5 serviços + ArgoCD).
# - Autoscaling configurado entre 1 e 3 nós (iniciando com 2 para alta disponibilidade).
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group-${var.environment}"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = 2 # Quantidade padrão de nós ativos
    min_size     = 1 # Mínimo em caso de baixa carga
    max_size     = 3 # Máximo permitido pelo autoscaling
  }

  update_config {
    max_unavailable = 1 # Garante que apenas 1 nó fique fora do ar durante atualizações (Zero Downtime)
  }

  tags = {
    Name = "${var.project_name}-node-group-${var.environment}"
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}
