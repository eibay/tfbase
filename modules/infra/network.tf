

resource "aws_internet_gateway" "aws-igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name        = "${var.app_name}-igw",
    Environment = var.app_environment
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  count                   = length(var.public_subnet_cidrs)
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws-igw.id
  }

  tags = {
    Name        = "${var.app_name}-public-routing-table",
    Environment = var.app_environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}


resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  count             = length(var.private_subnet_cidrs)
}

resource "aws_nat_gateway" "nat-gw" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [aws_internet_gateway.aws-igw]

  tags = {
    Name        = "${var.app_name}-igw",
    Environment = var.app_environment
  }
}

resource "aws_eip" "nat" {
  count      = length(var.private_subnet_cidrs)
  depends_on = [aws_internet_gateway.aws-igw]

  tags = {
    Name        = "${var.app_name}-elatic-ip"
    Environment = var.app_environment
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat-gw.*.id, 0)
  }

  tags = {
    Name        = "${var.app_name}-private-routing-table",
    Environment = var.app_environment
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}


