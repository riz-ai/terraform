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

variable "vpc" {
  description = "VPC configuration for the EKS cluster"
  type = object({
    id = string
    region = string
    private_subnets_with_nat    = list(string)
  })
}
