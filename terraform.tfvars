# VPC-specific Variables
vpc = {
  name  = "tf-vpc"
  region  = "us-east-1"
  cidr  = "10.11.0.0/16"
  subnets = {
    public  = {
      subnet1 = {
        cidr    = "10.11.1.0/24"
        az      = "us-east-1a"
        public  = true
      }
      subnet2 = {
        cidr    = "10.11.2.0/24"
        az      = "us-east-1b"
        public  = true
      }
      subnet3 = {
        cidr    = "10.11.3.0/24"
        az      = "us-east-1c"
        public  = true
      }
    }
    private = {
      subnet4 = {
        cidr    = "10.11.4.0/24"
        az      = "us-east-1a"
        private = true
      }
      subnet5 = {
        cidr    = "10.11.5.0/24"
        az      = "us-east-1b"
        private = true
      }
      subnet6 = {
        cidr    = "10.11.6.0/24"
        az      = "us-east-1c"
        private = true
      }
      subnet7 = {
        cidr    = "10.11.7.0/24"
        az      = "us-east-1a"
        private = true
      }
      subnet8 = {
        cidr    = "10.11.8.0/24"
        az      = "us-east-1b"
        private = true
      }
      subnet9 = {
        cidr    = "10.11.9.0/24"
        az      = "us-east-1c"
        private = true
      }
    }
  }
  tags = {
    vpc                               = { Name = "tf-vpc" }
    internet_gateway                  = { Name = "tf-igw" }
    nat_gateway                       = { Name = "tf-ngw" }
    elastic_ip                        = { Name = "tf-eip" }
    public_route_table                = { Name = "tf-public-rt" }
    private_route_table_with_nat      = { Name = "tf-private-rt-with-nat" }
    private_route_table_without_nat   = { Name = "tf-private-rt-without-nat" }
  }
}

# EKS-specific Variables
eks = {
  cluster_name                      = "eks-demo"
  node_group_name                   = "eks-demo-node-group"
  node_group_instance_types         = ["t3.small"]
  node_group_desired_size           = 1
  node_group_max_size               = 2
  node_group_min_size               = 1
}
# GitHub repository URL 
git_repo_url = "https://github.com/Ecolibrium-Energy/Helm.git"

ebs_csi = {
  account_id	= "801935342396"
  role_name	= "AWS_EBS_CSI_DriverRole"
  kms_policy_name	= "KMS_Key_For_EBS_CSI_Driver"
  
# Storage Class Variables
  storage_class_name     = "ebs-sc"
  volume_type            = "gp3"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
 
 # Tags
  tags = {
    Name = "EBS-CSI-KMS-Key"
  }
}

alb = {
  alb_role_name     = "AWSEKSLoadBalancerControllerRole"
  alb_sa_name       = "aws-load-balancer-controller"
  alb_sa_namespace  = "kube-system"
  cluster_name      = "eks-demo"
  account_id      = "801935342396"
}

