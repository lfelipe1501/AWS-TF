# Terraform for Ubuntu on AWS :sunglasses:

<img src="https://raw.githubusercontent.com/lfelipe1501/lfelipe-projects/master/Terraform/TerraFUbuntu.svg" alt="tfubn-logo" width="256" />

This repository contains Terraform configurations to deploy and manage Ubuntu servers on AWS. It includes automated server configuration, network setup, security rules, and SSH security hardening.

## Features

- Automated deployment of Ubuntu servers on AWS
- Custom SSH port and security configuration
- Security group configuration with fail2ban
- VPC and subnet configuration (public and private)
- Cloud-init for initial server configuration
- Conditional SSH password authentication
- Custom hostname configuration
- Waits for cloud-init to complete before displaying connection details
- Elastic IP support (optional)

## Requirements

- Terraform >= 1.0.0
- AWS Account
- Configured AWS credentials
- SSH key pair

## File Structure

- `main.tf`: Main resource configuration
- `variables.tf`: Variable definitions
- `terraform.tfvars.template`: Template for variable values (copy to terraform.tfvars)
- `outputs.tf`: Deployment outputs
- `provider.tf`: Provider configuration
- `versions.tf`: Required versions and providers
- `scripts/cloud-init-ubuntu.yaml`: Cloud-init configuration for server setup

## Quick Start

1. Clone this repository:

   ```bash
   git clone https://github.com/lfelipe1501/AWS-TF.git
   cd AWS-TF
   ```

2. Create your configuration file from the template:

   ```bash
   cp terraform.tfvars.template terraform.tfvars
   ```

3. Configure your variables in `terraform.tfvars`:
   - Configure your AWS region
   - Configure SSH settings (public key path, port)
   - Set username, password, and hostname
   - Adjust instance specifications as needed
   - Configure network settings
   - Update allowed SSH IPs for better security

4. Initialize Terraform:

   ```bash
   terraform init
   ```

5. Plan the deployment:

   ```bash
   terraform plan
   ```

6. Apply the configuration:

   ```bash
   terraform apply
   ```

7. Connect to your server using the connection details provided in the output.

8. To destroy the infrastructure:

   ```bash
   terraform destroy
   ```

## Key Variables

| Variable | Description | Default Value |
|----------|-------------|---------|
| `aws_region` | AWS Region | us-east-1 |
| `ubuntu_instances_count` | Number of Ubuntu instances to deploy | 1 |
| `ssh_public_key_path` | Path to SSH public key file | ~/.ssh/id_rsa.pub |
| `ssh_port` | Custom SSH port | 2255 |
| `ssh_password_authentication` | Enable/disable SSH password authentication | false |
| `username` | Username for the server | ubuntu |
| `password` | Password for the user | - |
| `hostname` | Custom hostname for the server | "" (uses instance name) |
| `instances` | Instance configuration (type, AMI, availability zone) | See terraform.tfvars.template |
| `allowed_ssh_ips` | IPs allowed to connect via SSH | ["0.0.0.0/0"] |
| `create_elastic_ip` | Create and associate Elastic IPs to instances | true |

## Outputs

After deployment, Terraform will display:

- `ubuntu_instance_ips`: Public IPs of the instances
- `ubuntu_instance_private_ips`: Private IPs of the instances
- `ubuntu_instance_status`: Status of the instances
- `ubuntu_instance_dns`: DNS names of the instances
- `vpc_info`: VPC information
- `subnet_info`: Subnet information
- `ssh_connection_strings`: Ready-to-use SSH connection commands
- `connection_instructions`: Detailed connection instructions

## Security Considerations

- Default configuration disables SSH password authentication (key-based only)
- Uses a custom SSH port (2255) instead of the default port 22
- Security group is configured to allow only necessary connections
- Fail2ban is installed to protect against brute force attacks
- **Important**: Update `allowed_ssh_ips` in your `terraform.tfvars` to restrict SSH access to only your IP addresses

## Customization

You can customize the deployment by modifying:

1. `terraform.tfvars` for basic configuration (copy from terraform.tfvars.template)
2. `variables.tf` to add new variables or change default values
3. `scripts/cloud-init-ubuntu.yaml` for server initialization tasks

## Troubleshooting

- If you cannot connect to the server, verify that:
  - Your SSH key is properly configured
  - The server has finished initializing (cloud-init complete)
  - Your IP is allowed in the security group rules
  - You are using the correct SSH port

- To check cloud-init logs on the server:

  ```bash
  sudo cat /var/log/cloud-init-output.log
  ```
  