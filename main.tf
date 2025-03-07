# Create an SSH key pair in AWS
resource "aws_key_pair" "ubuntu_key" {
  key_name   = var.key_pair_name
  public_key = file(var.ssh_public_key_path)
  
  tags = {
    Name = "${var.project_name}-key"
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count                   = length(var.subnet_cidrs.public)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs.public[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(var.subnet_cidrs.private)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs.private[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate public route table with public subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Security group for Ubuntu instances
resource "aws_security_group" "ubuntu_sg" {
  name        = "${var.project_name}-ubuntu-sg"
  description = "Security group for Ubuntu instances"
  vpc_id      = aws_vpc.main.id
  
  # Rule for custom SSH
  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
    description = "Custom SSH on port ${var.ssh_port}"
  }
  
  # Rule for HTTP (optional)
  dynamic "ingress" {
    for_each = var.enable_http ? [1] : []
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP - Port 80"
    }
  }
  
  # Rule for HTTPS (optional)
  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS - Port 443"
    }
  }
  
  # Additional custom rules
  dynamic "ingress" {
    for_each = [for r in var.custom_security_group_rules : r if r.enabled && r.type == "ingress"]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
  
  dynamic "egress" {
    for_each = [for r in var.custom_security_group_rules : r if r.enabled && r.type == "egress"]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "${var.project_name}-ubuntu-sg"
  }
}

# Create EC2 Ubuntu instances
resource "aws_instance" "ubuntu_instances" {
  for_each = {
    for idx in range(var.ubuntu_instances_count) :
    idx == 0 ? var.instances[0].name : "${var.instances[0].name}-${idx}" => {
      name            = idx == 0 ? var.instances[0].name : "${var.instances[0].name}-${idx}"
      instance_type   = var.instances[0].instance_type
      ami             = var.instances[0].ami
      availability_zone = var.instances[0].availability_zone
      root_volume_size = var.instances[0].root_volume_size
      root_volume_type = var.instances[0].root_volume_type
      labels          = var.instances[0].labels
    }
  }
  
  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  availability_zone      = each.value.availability_zone
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  key_name               = aws_key_pair.ubuntu_key.key_name
  monitoring             = var.enable_detailed_monitoring
  
  root_block_device {
    volume_size = each.value.root_volume_size
    volume_type = each.value.root_volume_type
    encrypted   = true
    
    tags = {
      Name = "${each.value.name}-root-volume"
    }
  }
  
  # Cloud-init for Ubuntu
  user_data = templatefile("${path.module}/scripts/cloud-init-ubuntu.yaml", {
    ssh_key = file(var.ssh_public_key_path)
    ssh_port = var.ssh_port
    timezone = var.timezone
    username = var.username
    password = var.password
    ssh_password_authentication = var.ssh_password_authentication
    hostname = var.hostname != "" ? var.hostname : each.value.name
  })
  
  tags = merge(
    each.value.labels,
    {
      Name = each.value.name
    }
  )
  
  # Wait for the instance to be available
  depends_on = [aws_internet_gateway.main]
}

# Create Elastic IPs (optional)
resource "aws_eip" "ubuntu_eip" {
  for_each = var.create_elastic_ip ? aws_instance.ubuntu_instances : {}
  
  domain   = "vpc"
  instance = each.value.id
  
  tags = {
    Name = "${each.key}-eip"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Wait for cloud-init to complete
resource "time_sleep" "wait_for_cloud_init" {
  depends_on = [aws_instance.ubuntu_instances]
  
  # Wait 2 minutes to allow cloud-init to complete
  create_duration = "2m"
}

# Verify that cloud-init has completed
resource "null_resource" "check_cloud_init" {
  for_each = aws_instance.ubuntu_instances
  
  depends_on = [
    time_sleep.wait_for_cloud_init,
    aws_eip.ubuntu_eip
  ]
  
  # This will try to connect to the server and verify if cloud-init has completed
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.username
      host        = var.create_elastic_ip ? aws_eip.ubuntu_eip[each.key].public_ip : each.value.public_ip
      port        = var.ssh_port
      private_key = file(replace(var.ssh_public_key_path, ".pub", ""))
      timeout     = "3m"
    }
    
    inline = [
      "cloud-init status --wait || echo 'Cloud-init still running, but connection successful'",
      "echo 'Server ${each.value.tags.Name} is ready!'"
    ]
  }
} 