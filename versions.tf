terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.45"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}
