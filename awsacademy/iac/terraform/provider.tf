terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  # Backend S3 para armazenar o estado remotamente (boas práticas).
  # Antes de ativar, crie o bucket: aws s3 mb s3://<nome-unico-do-bucket>
  # e substitua o valor de bucket abaixo.
  #
  # backend "s3" {
  #   bucket = "devops20240222"
  #   key    = "state"
  # }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.regiao
}
