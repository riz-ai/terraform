variable "alb_role_name" {
  description = "Name of the IAM role for ALB Ingress Controller"
  type        = string
}

variable "alb_sa_name" {
  description = "Name of the Kubernetes service account for ALB Ingress Controller"
  type        = string
}

variable "alb_sa_namespace" {
  description = "Namespace for ALB Ingress Controller"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}
variable "region" {
  description = "AWS region where the EKS cluster is located"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint URL"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for the EKS cluster"
  type        = string
}

variable "eks_token" {
  description = "Authentication token for EKS cluster"
  type        = string
}
variable "vpc_id" {
  description = "The VPC ID where the EKS cluster is running"
  type        = string
}
variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider associated with the EKS cluster"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}
