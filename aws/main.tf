provider "aws" {
  region = "us-east-1"
  profile = "main-profile" # defined in ~/.aws/credentials
}

# 1. Create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

# 3. Create Custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }

}

# 4. Create a Subnet
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-subnet"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create Security Group to allow port 22, 80, 443
resource "aws_security_group" "allow_web_traffic" {
  name = "allow_web_traffic"
  description = "Allow Web Traffic"
  vpc_id = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port = 443 # range start
    to_port = 443 # range end
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # what subnets can reach this
  }

  ingress {
    description = "HTTP"
    from_port = 80 # range start
    to_port = 80 # range end
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # what subnets can reach this
  }

  ingress {
    description = "SSH"
    from_port = 22 # range start
    to_port = 22 # range end
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # what subnets can reach this
  }

  egress {
    from_port = 0 # any
    to_port = 0 # any
    protocol = "-1" # any
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id = aws_subnet.subnet-1.id
  private_ips = ["10.0.1.50"] # must be within our subnet
  security_groups = [aws_security_group.allow_web_traffic.id]
}

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc = true
  network_interface = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "web-server-instance" {
  ami = "ami-0e472ba40eb589f49"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key" # Where we reference our RSA Key

  network_interface {
    device_index = 0 # NIC set to eth0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c "echo your very first web server > /var/www/html/index.html"
            EOF

  tags = {
    Name = "web-server"
  }
}

