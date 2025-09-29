resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_prefix}-vpc"
  }
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets
  vpc_id = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_prefix}-subnet-public-${replace(each.value.az, "ap-northeast-", "")}"
  }
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets
  vpc_id = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  tags = {
    Name = "${var.project_prefix}-subnet-private-${replace(each.value.az, "ap-northeast-", "")}-${each.value.role}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_prefix}-igw"
  }
}

# ==============================
# Public Route Table
# ==============================

resource "aws_route_table" "public" {
  for_each = local.public_azs
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_prefix}-rtb-public-${replace(each.key, "ap-northeast-", "")}"
  }
}

resource "aws_route" "default_via_igw" {
  for_each = aws_route_table.public
  route_table_id = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.value.az].id
}

# ==============================
# NAT Gateway
# ==============================

resource "aws_eip" "nat" {
  tags = {
    Name = "${var.project_prefix}-eip-ap-northeast-1a"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public["public_ap_northeast_1a"].id
  tags = {
    Name = "${var.project_prefix}-nat-gw-ap-northeast-1a"
  }
  depends_on = [ aws_internet_gateway.igw ]
}

# ==============================
# Private Route Table
# ==============================

resource "aws_route_table" "private" {
  for_each = local.private_azs
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_prefix}-rtb-private-${replace(each.key, "ap-northeast-", "")}"
  }
}

resource "aws_route" "default_via_nat" {
  for_each = aws_route_table.private
  route_table_id = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets
  subnet_id = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.value.az].id
}