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