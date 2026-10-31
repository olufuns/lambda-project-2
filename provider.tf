terraform {
  required_version = "~>1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket = "morays-terraform-state"
    region = "eu-west-2"
    key    = "morays-terraform-lambda/terraform.tfstate"
  }

}

provider "aws" {
  region = "eu-west-2"
}