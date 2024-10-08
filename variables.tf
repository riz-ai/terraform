# Define the variables for the VPC and its subnets
variable "vpc" {
  description = "Configuration for the VPC and subnets"
  type = object({
    name    = string
    region  = string
    cidr    = string
    subnets = object({
      public  = map(object({
        cidr   = string
        az     = string
        public = bool
      }))
      private = map(object({
        cidr    = string
        az      = string
        private = bool
      }))
    })
    tags = object({
      # Define the tags for various resources
      vpc                               = map(string)
      internet_gateway                  = map(string)
      nat_gateway                       = map(string)
      elastic_ip                        = map(string)
      public_route_table                = map(string)
      private_route_table_with_nat      = map(string)
      private_route_table_without_nat   = map(string)
    })
  })
}

# Define the variables for the EKS and its resources
variable "eks"  {
  description = "EKS-specific variables"  
  type = object({
    cluster_name                = string
    node_group_name             = string
    node_group_instance_types   = list(string)
    node_group_desired_size     = number
    node_group_max_size         = number
    node_group_min_size         = number
  })
}

# Define variables for ebs_csi_driver
variable "ebs_csi" {
  description   = "ebs_csi driver variables"
  type  = object({
    account_id         = string
    role_name          = string
    kms_policy_name    = string
    storage_class_name = string
    volume_type        = string
    volume_binding_mode = string
    allow_volume_expansion = bool
    oidc_provider_url  = optional(string)
    kms_key_arn        = optional(string)
    tags = map(string)
  })
}

variable "alb" {
  description = "Configuration for ALB Ingress Controller"
  type = object({
    alb_role_name     = string
    alb_sa_name       = string
    alb_sa_namespace  = string
    cluster_name      = string
    account_id      = string
  })
}

# GitHub repository URL
variable "git_repo_url" {
  description = "The URL of the GitHub repository to clone"
  type        = string
}

# Optional: Define vpc_id to explicitly reference it when needed
variable "vpc_id" {
  description = "The VPC ID to be used in ALB and other configurations."
  type        = string
  default     = ""  
}

variable "argocd" {
  description = "ArgoCD-specific variables"
  type = object({
    namespace           = string
    argocd_host        = string
    acm_certificate_arn = string
  })
}

