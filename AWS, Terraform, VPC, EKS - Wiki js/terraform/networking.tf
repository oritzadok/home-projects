resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env_name}-vpc"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.env_name}-igw"
  }
}


resource "aws_subnet" "public" {
  for_each                = { for idx, az in var.azs : idx => az }
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[each.key]
  availability_zone       = "${var.aws_region}${each.value}"
  map_public_ip_on_launch = true

  tags = {
    Name                       = "${var.env_name}-public-${each.key}"
    # For AWS load balancer controller to know that can be used for external load balancers
    "kubernetes.io/role/elb"   = "1"
  }
}


# Single route table for all public subnets, routes to an internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env_name}-public-rt"
  }
}


resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}


resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"

  tags = {
    Name = "${var.env_name}-nat-eip-${each.key}"
  }
}


resource "aws_nat_gateway" "ngw" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.env_name}-nat-${each.key}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}


resource "aws_subnet" "private" {
  for_each          = { for idx, az in var.azs : idx => az }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidrs[each.key]
  availability_zone = "${var.aws_region}${each.value}"

  tags = {
    Name                            = "${var.env_name}-private-${each.key}"
    # For AWS load balancer controller to know that can be used for internal load balancers
    "kubernetes.io/role/internal-elb" = "1"
  }
}


# Route table for each private subnet, routes to a NAT gateway in a public subnet
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[each.key].id
  }

  tags = {
    Name = "${var.env_name}-private-rt-${each.key}"
  }
}


resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}