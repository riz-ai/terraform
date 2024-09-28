# Download the IAM Policy JSON file for ALB Ingress Controller
resource "null_resource" "download_iam_policy" {
  provisioner "local-exec" {
    command = "curl -o /home/ubuntu/iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
  }
}

# Create IAM Policy for ALB Ingress Controller
data "local_file" "iam_policy_content" {
  filename = "/home/ubuntu/iam_policy.json"
  depends_on = [null_resource.download_iam_policy]
}

resource "aws_iam_policy" "alb_ingress_controller_policy" {
  name   = "AWSLBControllerIAMPolicy"
  path   = "/"
  policy = data.local_file.iam_policy_content.content

  depends_on = [null_resource.download_iam_policy]
}

# Assume Role Policy for ALB Ingress Controller
data "aws_iam_policy_document" "alb_ingress_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/${replace(var.oidc_provider_arn, "https://", "")}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.alb_sa_namespace}:${var.alb_sa_name}"]
    }
  }
}

# Create IAM Role and attach the policy
resource "aws_iam_role" "alb_ingress_role" {
  name               = var.alb_role_name
  assume_role_policy = data.aws_iam_policy_document.alb_ingress_assume_role_policy.json
}

# Attach the IAM Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "alb_ingress_policy_attach" {
  role       = aws_iam_role.alb_ingress_role.name
  policy_arn = aws_iam_policy.alb_ingress_controller_policy.arn
}

# Create Service Account in Kubernetes
resource "kubernetes_service_account" "alb_sa" {
  metadata {
    name      = var.alb_sa_name
    namespace = var.alb_sa_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_ingress_role.arn
    }
  }

  automount_service_account_token = true
}

# Install ALB Ingress Controller using Helm
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = var.alb_sa_namespace
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = var.alb_sa_name
  }

  set {
    name  = "region"
    value = var.region  # Specify your AWS region explicitly from the variable passed from the root
  }

  set {
    name  = "vpcId"
    value = var.vpc_id  # Ensure the VPC ID is passed correctly.
  }
}

# Ensure Kubernetes provider is correctly configured inside the root and pass necessary variables
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  token                  = var.eks_token
}
