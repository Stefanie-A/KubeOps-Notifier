#vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc"
  }
}

# igw
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw"
  }
}

#public subnet
resource "aws_subnet" "public_subnet" {
  count                   = length(var.pub_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.pub_subnets_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

#public subnet route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }
  tags = {
    Name = "publicRouteTable"
  }
}

#route table association with public subnet
resource "aws_route_table_association" "name" {
  count          = length(var.pub_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

#Elastic ip for NAT
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.vpc_igw]
}

#private subnet
resource "aws_subnet" "private_subnet" {
  count                   = length(var.pri_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.pri_subnets_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name = "Subnet-${count.index + 1}"
  }
}

#nat gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id
  depends_on    = [aws_internet_gateway.vpc_igw]
}
#private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "private subnet route table"
  }
}
resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.pri_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}

