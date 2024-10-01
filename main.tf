terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
# Fetch GitHub token from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "git_token" {
  secret_id = "arn:aws:secretsmanager:us-east-1:11111111111:secret:git_token-xxxxx" # use correct secret_arn
}

locals {
  github_token = jsondecode(data.aws_secretsmanager_secret_version.git_token.secret_string)["git_token"]
}
module "vpc" {
  source  = "./modules/VPC"

  vpc = var.vpc
}

module "eks" {
  source  = "./modules/EKS"

  eks = var.eks

  vpc = {
    id                        = module.vpc.vpc_id
    private_subnets_with_nat  = module.vpc.private_subnets_with_nat
    region                    = var.vpc.region
  }
}

# Data source for EKS authentication token
data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name  
}

# Kubernetes provider using EKS cluster info
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks.token
}
# Helm provider using the Kubernetes info
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
# GitHub module for cloning Helm repository
module "git_repo" {
  source   = "./modules/GIT"
  repo_url = var.git_repo_url
  github_token = local.github_token
}

module "ebs_csi_driver" {
  source               = "./modules/EBS_CSI"

  # Variables
  account_id           = var.ebs_csi.account_id
  role_name            = var.ebs_csi.role_name
  oidc_provider_url    = module.eks.cluster_oidc_issuer_url
  kms_policy_name      = var.ebs_csi.kms_policy_name
  cluster_name         = module.eks.cluster_name
  storage_class_name   = var.ebs_csi.storage_class_name


  # Module to be executed after the EKS cluster creation
  depends_on = [module.eks]
}

module "alb_ingress_controller" {
  source  = "./modules/ALB"

  alb_role_name      = var.alb.alb_role_name
  alb_sa_name        = var.alb.alb_sa_name
  alb_sa_namespace   = var.alb.alb_sa_namespace
  cluster_name       = module.eks.cluster_name
  region                       = "us-east-1"  # Set your AWS region
  cluster_endpoint             = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  eks_token                    = data.aws_eks_cluster_auth.eks.token
  vpc_id                    = module.vpc.vpc_id
  oidc_provider_arn                    = module.eks.cluster_oidc_issuer_url
  account_id                    = var.alb.account_id

}

module "argocd" {
  source                 = "./modules/argocd"
  namespace              = "argocd"
  alb_subnets            = module.vpc.public_subnet_ids
  acm_certificate_arn    = var.argocd.acm_certificate_arn
  argocd_host           = var.argocd.argocd_host

  git_repo_clone_directory = module.git_repo.repository_clone_directory

  depends_on = [module.git_repo]
}
