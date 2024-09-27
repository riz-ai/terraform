output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.tf-vpc.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.tf-igw.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.tf-nat.id
}

output "nat_gateway_public_ip" {
  description = "The public IP address of the NAT Gateway"
  value       = aws_eip.tf-nat.public_ip
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
  #value = {
  #  for subnet in aws_subnet.public : 
  #  subnet.availability_zone => subnet.id
    #for az, subnet in aws_subnet.public : az => subnet.id
  }

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.tf-public.id
}

output "private_route_table_with_nat_id" {
  description = "ID of the private route table with NAT gateway"
  value       = aws_route_table.tf-private-with-nat.id
}

output "private_route_table_without_nat_id" {
  description = "ID of the private route table without NAT gateway"
  value       = aws_route_table.tf-private-without-nat.id
}

output "private_subnets_with_nat" {
  description = "IDs of private subnets with NAT gateway access"
  value       = [for k, v in aws_subnet.private : v.id if contains(["subnet4", "subnet5", "subnet6"], k)]
}

output "private_subnets_without_nat" {
  description = "IDs of private subnets without NAT gateway access"
  value       = [for k, v in aws_subnet.private : v.id if contains(["subnet7", "subnet8", "subnet9"], k)]
}