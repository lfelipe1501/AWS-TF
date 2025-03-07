provider "aws" {
  region = var.aws_region
  
  # Si necesitas configurar perfiles específicos de AWS CLI
  # profile = var.aws_profile
  
  # Opcional: Etiquetas predeterminadas para todos los recursos
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
} 