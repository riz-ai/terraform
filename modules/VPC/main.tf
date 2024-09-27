locals {
  primary_public_subnet = "subnet1"
}

resource "aws_vpc" "tf-vpc" {
  cidr_block = var.vpc.cidr

  tags = var.vpc.tags.vpc
}

resource "aws_internet_gateway" "tf-igw" {
  vpc_id = aws_vpc.tf-vpc.id

  tags = var.vpc.tags.internet_gateway
}

resource "aws_subnet" "public" {
  for_each = var.vpc.subnets.public

  vpc_id                  = aws_vpc.tf-vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    var.vpc.tags.public_route_table,
    { Name = "public-${each.key}" }
  )
}

resource "aws_subnet" "private" {
  for_each = var.vpc.subnets.private

  vpc_id            = aws_vpc.tf-vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    var.vpc.tags.private_route_table_with_nat,
    { Name = "private-${each.key}" }
  )
}

resource "aws_eip" "tf-nat" {
  domain = "vpc"

  tags = var.vpc.tags.elastic_ip
}

resource "aws_nat_gateway" "tf-nat" {
  allocation_id = aws_eip.tf-nat.id
  subnet_id     = aws_subnet.public[local.primary_public_subnet].id

  tags = var.vpc.tags.nat_gateway

  depends_on = [aws_internet_gateway.tf-igw]
}

resource "aws_route_table" "tf-public" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-igw.id
  }

  tags = var.vpc.tags.public_route_table
}

resource "aws_route_table" "tf-private-with-nat" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tf-nat.id
  }

  tags = var.vpc.tags.private_route_table_with_nat
}

resource "aws_route_table" "tf-private-without-nat" {
  vpc_id = aws_vpc.tf-vpc.id

  tags = var.vpc.tags.private_route_table_without_nat
}

resource "aws_route_table_association" "public" {
  for_each = var.vpc.subnets.public

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.tf-public.id
}

resource "aws_route_table_association" "private-with-nat" {
  for_each = {
    for subnet_key in ["subnet4", "subnet5", "subnet6"] : subnet_key => var.vpc.subnets.private[subnet_key]
  }

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.tf-private-with-nat.id
}

resource "aws_route_table_association" "private-without-nat" {
  for_each = {
    for subnet_key in ["subnet7", "subnet8", "subnet9"] : subnet_key => var.vpc.subnets.private[subnet_key]
  }

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.tf-private-without-nat.id
}