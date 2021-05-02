### Network ###
resource "aws_vpc" "dms-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name    = "DMS"
    project = "dms"
  }
}
resource "aws_vpc_dhcp_options" "default" {
  domain_name         = "ec2.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = {
    Name    = "DMS"
    project = "dms"
  }
}
resource "aws_network_acl" "default" {
  vpc_id = aws_vpc.dms-vpc.id
  egress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = ""
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }
  ingress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = ""
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }
  tags = {
    Name    = "DMS"
    project = "dms"
  }
}
resource "aws_internet_gateway" "dms-igw" {
  vpc_id = aws_vpc.dms-vpc.id
  tags = {
    Name    = "DMS"
    project = "dms"
  }
}
data "aws_availability_zones" "available" {}
resource "aws_subnet" "dms-cluster-subnet-blue-public" {
  vpc_id     = aws_vpc.dms-vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = "10.0.0.0/24"
  tags = {
    Name    = "DMS Public Blue"
    project = "dms"
  }
}
resource "aws_subnet" "dms-cluster-subnet-green-public" {
  vpc_id     = aws_vpc.dms-vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = "10.0.1.0/24"
  tags = {
    Name    = "DMS Public Green"
    project = "dms"
  }
}
resource "aws_subnet" "dms-cluster-subnet-blue-private" {
  vpc_id     = aws_vpc.dms-vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = "10.0.2.0/24"
  tags = {
    Name    = "DMS Blue Private"
    project = "dms"
  }
}
resource "aws_subnet" "dms-cluster-subnet-green-private" {
  vpc_id     = aws_vpc.dms-vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = "10.0.3.0/24"
  tags = {
    Name    = "DMS Green Private"
    project = "dms"
  }
}
resource "aws_route_table" "dms-igw" {
  vpc_id = aws_vpc.dms-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dms-igw.id
  }
  tags = {
    Name    = "DMS"
    project = "dms"
  }
}
resource "aws_route_table_association" "subnet_assoc_public-blue" {
  subnet_id      = aws_subnet.dms-cluster-subnet-blue-public.id
  route_table_id = aws_route_table.dms-igw.id
}
resource "aws_route_table_association" "subnet_assoc_public-green" {
  subnet_id      = aws_subnet.dms-cluster-subnet-green-public.id
  route_table_id = aws_route_table.dms-igw.id
}
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.dms-igw]
}

resource "aws_nat_gateway" "dms-ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.dms-cluster-subnet-blue-public.id
  depends_on = [aws_internet_gateway.dms-igw]
  tags = {
    Name    = "DMS"
    project = "dms"
  }
}
resource "aws_route_table" "dms-ngw" {
  vpc_id = aws_vpc.dms-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dms-ngw.id
  }
  tags = {
    Name    = "DMS"
    project = "dms"
  }
}
resource "aws_route_table_association" "subnet_assoc_blue_private" {
  subnet_id      = aws_subnet.dms-cluster-subnet-blue-private.id
  route_table_id = aws_route_table.dms-ngw.id
}
resource "aws_route_table_association" "subnet_assoc_green_private" {
  subnet_id      = aws_subnet.dms-cluster-subnet-green-private.id
  route_table_id = aws_route_table.dms-ngw.id
}