output "ubuntu_instance_ips" {
  description = "Public IPs of Ubuntu instances"
  value = {
    for name, instance in aws_instance.ubuntu_instances : name => var.create_elastic_ip ? aws_eip.ubuntu_eip[name].public_ip : instance.public_ip
  }
  depends_on = [null_resource.check_cloud_init]
}

output "ubuntu_instance_private_ips" {
  description = "Private IPs of Ubuntu instances"
  value = {
    for name, instance in aws_instance.ubuntu_instances : name => instance.private_ip
  }
  depends_on = [null_resource.check_cloud_init]
}

output "ubuntu_instance_status" {
  description = "Status of Ubuntu instances"
  value = {
    for name, instance in aws_instance.ubuntu_instances : name => instance.instance_state
  }
  depends_on = [null_resource.check_cloud_init]
}

output "ubuntu_instance_dns" {
  description = "Public DNS names of Ubuntu instances"
  value = {
    for name, instance in aws_instance.ubuntu_instances : name => var.create_elastic_ip ? aws_eip.ubuntu_eip[name].public_dns : instance.public_dns
  }
  depends_on = [null_resource.check_cloud_init]
}

output "vpc_info" {
  description = "VPC information"
  value = {
    vpc_id   = aws_vpc.main.id
    vpc_cidr = aws_vpc.main.cidr_block
  }
}

output "subnet_info" {
  description = "Subnet information"
  value = {
    public_subnets = {
      for idx, subnet in aws_subnet.public : "public-${idx}" => {
        id         = subnet.id
        cidr_block = subnet.cidr_block
        az         = subnet.availability_zone
      }
    }
    private_subnets = {
      for idx, subnet in aws_subnet.private : "private-${idx}" => {
        id         = subnet.id
        cidr_block = subnet.cidr_block
        az         = subnet.availability_zone
      }
    }
  }
}

output "ssh_connection_strings" {
  description = "SSH connection strings for each instance"
  value = {
    for name, instance in aws_instance.ubuntu_instances : name => "ssh -p ${var.ssh_port} ${var.username}@${var.create_elastic_ip ? aws_eip.ubuntu_eip[name].public_ip : instance.public_ip}"
  }
  depends_on = [null_resource.check_cloud_init]
}

output "connection_instructions" {
  description = "Instructions for connecting to the instances"
  value = <<-EOT
    =====================================================================
    SERVER CONNECTION
    =====================================================================
    
    To connect to your instances, use the following commands:
    
    ${join("\n    ", [
      for name, instance in aws_instance.ubuntu_instances : 
      "* ${name}: ssh -p ${var.ssh_port} ${var.username}@${var.create_elastic_ip ? aws_eip.ubuntu_eip[name].public_ip : instance.public_ip}"
    ])}
    
    Password authentication: ${var.ssh_password_authentication ? "ENABLED" : "DISABLED"}
    ${var.ssh_password_authentication ? "You can use the configured password to log in." : "You can only connect using your private SSH key."}
    
    =====================================================================
  EOT
  depends_on = [null_resource.check_cloud_init]
} 