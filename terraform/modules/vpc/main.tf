resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })

}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_block_subnet_1
  availability_zone = var.az_subnet_1
  tags = merge(var.tags, {
    Name = "${var.project_name}-subnet-1"
  })
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_block_subnet_2
  availability_zone = var.az_subnet_2
  tags = merge(var.tags, {
    Name = "${var.project_name}-subnet-2"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id
}
