# VPC A: Service (ALB, EC2)
resource "aws_vpc" "vpc_a" {
  cidr_block           = var.vpc_a_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-VPC-A" }
}

# VPC B: Data (RDS)
resource "aws_vpc" "vpc_b" {
  cidr_block           = var.vpc_b_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-VPC-B" }
}

# VPC Peering Connection
resource "aws_vpc_peering_connection" "peering" {
  vpc_id      = aws_vpc.vpc_a.id
  peer_vpc_id = aws_vpc.vpc_b.id
  auto_accept = true
  tags        = { Name = "${var.project_name}-Peering" }
}

# Route Table - VPC B에서 VPC A로 가는 경로 추가
resource "aws_route" "b_to_a" {
  route_table_id            = aws_vpc.vpc_b.main_route_table_id
  destination_cidr_block    = aws_vpc.vpc_a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

# 인터넷 게이트웨이 (VPC A용)
resource "aws_internet_gateway" "igw_a" {
  vpc_id = aws_vpc.vpc_a.id
  tags   = { Name = "${var.project_name}-IGW-A" }
}

# Public 서브넷용 라우트 테이블
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_a.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_a.id
  }
  route {
    cidr_block                = aws_vpc.vpc_b.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }
  tags = { Name = "${var.project_name}-Public-RT" }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.vpc_a_public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_2" {
  subnet_id      = aws_subnet.vpc_a_public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway (Private 서브넷 아웃바운드용)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-NAT-EIP" }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.vpc_a_public_1.id
  tags          = { Name = "${var.project_name}-NAT-GW" }
}

# Private 서브넷용 라우트 테이블
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc_a.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  route {
    cidr_block                = aws_vpc.vpc_b.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }
  tags = { Name = "${var.project_name}-Private-RT" }
}

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.vpc_a_private.id
  route_table_id = aws_route_table.private_rt.id
}

# Public Subnet
resource "aws_subnet" "vpc_a_public_1" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-Public-1" }
}

resource "aws_subnet" "vpc_a_public_2" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.az_2
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-Public-2" }
}

# Private Subnet
resource "aws_subnet" "vpc_a_private" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.az_1
  tags              = { Name = "${var.project_name}-Private-1" }
}

resource "aws_subnet" "vpc_b_data_1" {
  vpc_id            = aws_vpc.vpc_b.id
  cidr_block        = var.data_subnet_1_cidr
  availability_zone = var.az_1
  tags              = { Name = "${var.project_name}-Data-1" }
}

resource "aws_subnet" "vpc_b_data_2" {
  vpc_id            = aws_vpc.vpc_b.id
  cidr_block        = var.data_subnet_2_cidr
  availability_zone = var.az_2
  tags              = { Name = "${var.project_name}-Data-2" }
}
