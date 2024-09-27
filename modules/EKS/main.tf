# IAM Role for EKS
resource "aws_iam_role" "eks" {
  name = var.eks.cluster_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "demo-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

# Create KMS key for EKS encryption
resource "aws_kms_key" "eks_secrets_encryption" {
  description              = "KMS key for EKS cluster encryption"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

# Create an alias for the KMS key
resource "aws_kms_alias" "eks_secrets_encryption_alias" {
  name          = "alias/eks-secrets-encryption"
  target_key_id = aws_kms_key.eks_secrets_encryption.key_id
}

# Custom Security Group for EKS Cluster
resource "aws_security_group" "eks-cluster-sg" {
  name        = "${var.eks.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for EKS Control Plane
resource "aws_security_group" "eks-control-plane-sg" {
  name        = "${var.eks.cluster_name}-control-plane-sg"
  description = "Security group for EKS Control Plane"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EKS Cluster
resource "aws_eks_cluster" "eks-demo" {
  name     = var.eks.cluster_name
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = var.vpc.private_subnets_with_nat
    endpoint_private_access = true
    endpoint_public_access = true

    security_group_ids = [
      aws_security_group.eks-cluster-sg.id,
      aws_security_group.eks-control-plane-sg.id
    ]
  }

  # Enable Secrets Encryption
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_secrets_encryption.arn
    }
  }

  # Enable Control Plane Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [aws_iam_role_policy_attachment.demo-AmazonEKSClusterPolicy]
}

# IAM Role for EKS Nodes
resource "aws_iam_role" "eks-nodes" {
  name = "${var.eks.cluster_name}-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }],
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-nodes.name
}

# EKS Node Group
resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.eks-demo.name
  node_group_name = var.eks.node_group_name
  node_role_arn   = aws_iam_role.eks-nodes.arn

  subnet_ids = var.vpc.private_subnets_with_nat

  capacity_type  = "ON_DEMAND"
  instance_types = var.eks.node_group_instance_types

  scaling_config {
    desired_size = var.eks.node_group_desired_size
    max_size     = var.eks.node_group_max_size
    min_size     = var.eks.node_group_min_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
  ]
}

# OpenID Connect Provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks-demo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks-demo.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "test_oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:aws-test"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "test_oidc" {
  assume_role_policy = data.aws_iam_policy_document.test_oidc_assume_role_policy.json
  name               = "test-oidc"
}

resource "aws_iam_policy" "test-policy" {
  name = "test-policy"

  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation"
      ]
      Effect   = "Allow"
      Resource = "arn:aws:s3:::*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.test_oidc.name
  policy_arn = aws_iam_policy.test-policy.arn
}

output "test_policy_arn" {
  value = aws_iam_role.test_oidc.arn
}
resource "null_resource" "kubectl" {
  depends_on = [aws_eks_cluster.eks-demo]

  provisioner "local-exec" {
    command = "aws eks --region ${var.vpc.region} update-kubeconfig --name ${var.eks.cluster_name}"
  }
}
