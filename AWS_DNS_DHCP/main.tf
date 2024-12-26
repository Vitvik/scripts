provider "aws" {
  region = "eu-west-1"
}

# VPC Configuration
resource "aws_vpc" "linux_lab_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = false
  enable_dns_support   = false

  tags = {
    Name = "Linux Lab VPC"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.linux_lab_vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Public Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.linux_lab_vpc.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Private Subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "linux_lab_igw" {
  vpc_id = aws_vpc.linux_lab_vpc.id

  tags = {
    Name = "Linux Lab Internet Gateway"
  }
}

# Route Table для публічної підмережі
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.linux_lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.linux_lab_igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Route Table для приватної підмережі
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.linux_lab_vpc.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.gateway_private.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

# Асоціації Route Tables з підмережами
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

# Security Group для Gateway
resource "aws_security_group" "gateway_sg" {
  name        = "gateway-sg"
  description = "Security group for Gateway server"
  vpc_id      = aws_vpc.linux_lab_vpc.id
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Gateway Security Group"
  }
}

# Security Group для клієнтів
resource "aws_security_group" "client_sg" {
  name        = "client-sg"
  description = "Security group for client instances"
  vpc_id      = aws_vpc.linux_lab_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Client Security Group"
  }
}

# Мережеві інтерфейси для Gateway
resource "aws_network_interface" "gateway_public" {
  subnet_id         = aws_subnet.public_subnet.id
  security_groups   = [aws_security_group.gateway_sg.id]
  source_dest_check = false
  
  tags = {
    Name = "Gateway Public Interface"
  }
}

resource "aws_network_interface" "gateway_private" {
  subnet_id         = aws_subnet.private_subnet.id
  security_groups   = [aws_security_group.gateway_sg.id]
  private_ips       = ["192.168.0.100"]
  source_dest_check = false
  
  tags = {
    Name = "Gateway Private Interface"
  }
}

# Gateway Server як NAT Instance
resource "aws_instance" "gateway" {
  ami           = "ami-0715d656023fe21b4"  # Debian 12 AMI
  instance_type = "t3.nano"  # Змінено на t3.nano
  key_name      = "serv_tren"
  
  network_interface {
    network_interface_id = aws_network_interface.gateway_public.id
    device_index        = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.gateway_private.id
    device_index        = 1
  }
  /*
  user_data = <<-EOF
              #!/bin/bash
              # Включаємо IP forwarding
              echo 1 > /proc/sys/net/ipv4/ip_forward
              
              # Встановлюємо iptables
              apt-get update
              apt-get install -y bind9 dnsutils bind9-doc
              apt-get install -y iptables-persistent
              
              # Налаштовуємо NAT правила
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              iptables -A FORWARD -i eth1 -j ACCEPT
              iptables -A FORWARD -o eth1 -j ACCEPT
              
              # Зберігаємо правила
              netfilter-persistent save
              
              # Запускаємо сервіс
              systemctl enable netfilter-persistent
              EOF
  */  
  tags = {
    Name = "Gateway Server"
  }
}

# Elastic IP для Gateway
resource "aws_eip" "gateway_eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.gateway_public.id
  depends_on                = [aws_internet_gateway.linux_lab_igw]
}

# Мережевий інтерфейс для Ubuntu Client 1
resource "aws_network_interface" "ubuntu_client1_nic" {
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.client_sg.id]
  #private_ips     = ["192.168.0.50"]

  tags = {
    Name = "Ubuntu Client 1 Interface"
  }
}

# Мережевий інтерфейс для Ubuntu Client 2
resource "aws_network_interface" "ubuntu_client2_nic" {
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.client_sg.id]
  #private_ips     = ["192.168.0.60"]

  tags = {
    Name = "Ubuntu Client 2 Interface"
  }
}

# Ubuntu Client 1
resource "aws_instance" "ubuntu_client1" {
  ami           = "ami-0694d931cee176e7d"  # Ubuntu 22.04 LTS AMI
  instance_type = "t3.nano"  # Змінено на t3.nano
  key_name      = "serv_tren"

  network_interface {
    network_interface_id = aws_network_interface.ubuntu_client1_nic.id
    device_index        = 0
  }

  tags = {
    Name = "Ubuntu Client 1"
  }
}

# Ubuntu Client 2
resource "aws_instance" "ubuntu_client2" {
  ami           = "ami-0694d931cee176e7d"  # Ubuntu 22.04 LTS AMI
  instance_type = "t3.nano"  # Змінено на t3.nano
  key_name      = "serv_tren"

  network_interface {
    network_interface_id = aws_network_interface.ubuntu_client2_nic.id
    device_index        = 0
  }

  tags = {
    Name = "Ubuntu Client 2"
  }
}

# Outputs для зручності
output "gateway_public_ip" {
  description = "Public IP of Gateway Server"
  value       = aws_eip.gateway_eip.public_ip
}

output "gateway_private_ip" {
  description = "Private IP of Gateway Server"
  value       = aws_network_interface.gateway_private.private_ip
}

output "ubuntu_client1_private_ip" {
  description = "Private IP of Ubuntu Client 1"
  value       = aws_network_interface.ubuntu_client1_nic.private_ip
}

output "ubuntu_client2_private_ip" {
  description = "Private IP of Ubuntu Client 2"
  value       = aws_network_interface.ubuntu_client2_nic.private_ip
}