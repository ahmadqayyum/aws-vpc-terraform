#Get VPC list
resource "null_resource" "get_vpc_list" {
  provisioner "local-exec" {
    on_failure  = "fail"
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
  echo -e "\x1B[31m************************* fetching VPC list from remote **************************************\x1B[0m"
  echo -e "\x1B[31mHere is the list of existing VPC\x1B[0m"
  echo -e "\x1B[31m$(aws ec2 describe-vpcs --region ${var.region} --output text | grep TAGS | awk ' {print $3} '| tr '\r\n' '\t')  \x1B[0m"
  echo -e "\x1B[31m***************************************END****************************************************\x1B[0m"
EOT
  }
  #  triggers = {
  #    always_run = "${timestamp()}"
  #  }
}


# Creating VPC
resource "aws_vpc" "VPC" {
  cidr_block = "${var.aws_ip_cidr_range}"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.env_prefix_name}-VPC"
  }
}


# Creating Subnets 1 in Public and 1 in Private
# Private Subnets
resource "aws_subnet" "PrivSubnet" {
  cidr_block = "${cidrsubnet(aws_vpc.VPC.cidr_block, 8, 2)}" # creating 10.0.2.0/24 subnet
  vpc_id = "${aws_vpc.VPC.id}"
  availability_zone = "${var.availibility_zones["zone1"]}"

  tags = {
    Name = "${var.env_prefix_name}-Priv Subnet"
  }
}


# Public Subnets
resource "aws_subnet" "PubSubnet" {
  cidr_block = "${cidrsubnet(aws_vpc.VPC.cidr_block, 8, 1)}" # creating 10.0.1.0/24 subnet
  vpc_id = "${aws_vpc.VPC.id}"
  availability_zone = "${var.availibility_zones["zone2"]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env_prefix_name}-Public Subnet"
  }
}


# Creating Internet Gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = "${aws_vpc.VPC.id}"
  tags = {
    Name = "${var.env_prefix_name}-Internet Gateway"
  }
}


# Creating Elastic IP for NAT Gateway and Creating NAT Gateway
resource "aws_eip" "EIP4NAT" {
  vpc = true
  tags = {
    Name = "${var.env_prefix_name}-Elastic IP for NAT GW"
  }
}

resource "aws_nat_gateway" "NATGW" {
  allocation_id = "${aws_eip.EIP4NAT.id}"
  subnet_id = "${aws_subnet.PubSubnet.id}"
  tags = {
    Name = "${var.env_prefix_name}-NAT GW"
  }
}


# Associating Main Routing Table for VPC
resource "aws_main_route_table_association" "MainRTAssoc" {
  route_table_id = "${aws_route_table.RTPrivate.id}"
  vpc_id = "${aws_vpc.VPC.id}"
}


# Creating Public Routing Table with Internet Gateway
resource "aws_route_table" "RTPublic" {
  vpc_id = "${aws_vpc.VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW.id}"
  }

  tags = {
    Name = "${var.env_prefix_name}-Public Routing Table"
  }
}

# Creating Private Routing Table with NAT Gateway (for ONLY Outgoing Internet Access for Private Resources)
resource "aws_route_table" "RTPrivate" {
  vpc_id = "${aws_vpc.VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.NATGW.id}"
  }
  tags = {
    Name = "${var.env_prefix_name}-Private Routing Table"
  }
}


# Association Subnets with Routing Tables (Public and Private)
resource "aws_route_table_association" "PrivRTAssoc2a" {
  subnet_id = "${aws_subnet.PrivSubnet.id}"
  route_table_id = "${aws_route_table.RTPrivate.id}"
}

resource "aws_route_table_association" "PubRTAssoc2a" {
  subnet_id = "${aws_subnet.PubSubnet.id}"
  route_table_id = "${aws_route_table.RTPublic.id}"
}


# Creating Security Groups
# This is a test group
resource "aws_security_group" "testec2sg" {
  name = "${var.env_prefix_name}-TestEC2SG"
  description = "${var.env_prefix_name} Test EC2 SG"
  vpc_id = "${aws_vpc.VPC.id}"
  tags = {
    Name = "${var.env_prefix_name}-SG for Test EC2"
  }
  lifecycle {
    create_before_destroy = true
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "local access"
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "local access"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "local access"
  }

  ingress {
  from_port = 0
   to_port = 0
   protocol = -1
   cidr_blocks = ["10.0.0.0/16"]
   description = "local access"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
