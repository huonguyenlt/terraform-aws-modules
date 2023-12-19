data "aws_availability_zones" "available" {}

locals {
  azs     = slice(data.aws_availability_zones.available.names, 0, var.azs)
  newbits = ceil(log(3 * var.azs, 2))
}

# Create a VPC
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  tags = {
    Name = var.name
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  count             = var.azs
  vpc_id            = aws_vpc.this.id
  cidr_block        = element([for k, v in local.azs : cidrsubnet(var.cidr_block, local.newbits, k)], count.index)
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.name}-public-${local.azs[count.index]}"
  }
}

# Create a private subnet
resource "aws_subnet" "private" {
  count             = var.azs
  vpc_id            = aws_vpc.this.id
  cidr_block        = element([for k, v in local.azs : cidrsubnet(var.cidr_block, local.newbits, k + var.azs)], count.index)
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.name}-private-${local.azs[count.index]}"
  }
}

# Create an database subnet
resource "aws_subnet" "database" {
  count             = var.azs
  vpc_id            = aws_vpc.this.id
  cidr_block        = element([for k, v in local.azs : cidrsubnet(var.cidr_block, local.newbits, k + 2 * var.azs)], count.index)
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.name}-database-${local.azs[count.index]}"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# Create an NAT gateway
resource "aws_eip" "this" {
  count  = var.azs
  domain = "vpc"
  tags = {
    Name = "${var.name}-natgw-${local.azs[count.index]}"
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.azs
  allocation_id = aws_eip.this[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.name}-natgw-${local.azs[count.index]}"
  }

  depends_on = [aws_internet_gateway.this]
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-public"
  }
}

# Create private route table
resource "aws_route_table" "private" {
  count  = var.azs
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-private-${local.azs[count.index]}"
  }
}

# Create database route table
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-database"
  }
}

# Route for IGW
resource "aws_route" "igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Route for NATGW
resource "aws_route" "natgw" {
  count                  = var.azs
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count          = var.azs
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count          = var.azs
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Route table associations for database subnets
resource "aws_route_table_association" "database" {
  count          = var.azs
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}





























