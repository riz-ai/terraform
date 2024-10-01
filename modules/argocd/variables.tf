variable "namespace" {
  description = "The namespace in which to deploy ArgoCD"
  type        = string
}

variable "git_repo_clone_directory" {
  description = "The directory where the Helm repository is cloned"
  type        = string
}

variable "argocd_host" {
  description = "The hostname for the ArgoCD ingress"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ACM certificate ARN for HTTPS ingress"
  type        = string
}

variable "alb_subnets" {
  description = "List of public subnets where ALB should be deployed"
  type        = list(string)
}

