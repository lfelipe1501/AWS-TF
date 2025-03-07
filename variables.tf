variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use (optional)"
  type        = string
  default     = "default"
}

variable "ubuntu_instances_count" {
  description = "Number of Ubuntu instances to deploy"
  type        = number
  default     = 1
}

variable "enable_ipv6" {
  description = "Enable or disable IPv6 for instances"
  type        = bool
  default     = false
}

variable "base_ip" {
  description = "Base IP for automatically assigning static IPs (last octets will be incremented)"
  type        = string
  default     = "10.0.1.2"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "timezone" {
  description = "Timezone for servers"
  type        = string
  default     = "UTC"
}

variable "username" {
  description = "Username for servers"
  type        = string
  default     = "ubuntu"
}

variable "password" {
  description = "Password for user (in production use a more secure method)"
  type        = string
  default     = "Us3rADM1234"
  sensitive   = true
}

variable "instances" {
  description = "Configuration of EC2 instances to deploy"
  type = list(object({
    name        = string
    instance_type = string
    ami         = string
    availability_zone = string
    root_volume_size = number
    root_volume_type = string
    labels      = map(string)
  }))
  default = [
    {
      name              = "ubuntu-server"
      instance_type     = "t2.micro"
      ami               = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS en us-east-1
      availability_zone = "us-east-1a"
      root_volume_size  = 20
      root_volume_type  = "gp3"
      labels      = { role = "web" }
    }
  ]
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "myproject"
}

variable "vpc_cidr" {
  description = "CIDR range for VPC"
  type        = string
  default     = "172.10.0.0/23"
}

variable "subnet_cidrs" {
  description = "CIDR ranges for subnets"
  type = object({
    public  = list(string)
    private = list(string)
  })
  default = {
    public  = ["172.10.1.0/28"]
    private = ["172.10.1.16/28"]
  }
}

variable "allowed_ssh_ips" {
  description = "Allowed IPs for SSH connection"
  type        = list(string)
  default     = ["0.0.0.0/0"] # We recommend restricting this in production
}

variable "ssh_port" {
  description = "Custom SSH port"
  type        = number
  default     = 2255
}

variable "enable_http" {
  description = "Enable or disable HTTP port (80)"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Enable or disable HTTPS port (443)"
  type        = bool
  default     = true
}

variable "custom_security_group_rules" {
  description = "Additional custom security group rules"
  type = list(object({
    enabled    = bool
    type       = string
    protocol   = string
    from_port  = number
    to_port    = number
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "ssh_password_authentication" {
  description = "Enable or disable SSH password authentication"
  type        = bool
  default     = false
}

variable "hostname" {
  description = "Hostname for the server (if not specified, the server name will be used)"
  type        = string
  default     = ""
}

variable "create_elastic_ip" {
  description = "Whether to create and associate Elastic IPs to instances"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for EC2 instances"
  type        = bool
  default     = false
}

variable "key_pair_name" {
  description = "Name for the AWS key pair"
  type        = string
  default     = "ubuntu-key"
} 