terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.0"
    }
  }
  #   backend "s3" {
  #     key            = "state/terraform.tfstate"
  #     bucket         = "tf-state12345"
  #     region         = "us-east-1"
  #     dynamodb_table = "tf-state-lock"
  #     encrypt        = true
  #   }
  required_version = ">=1.8.0"
}

provider "aws" {
  region = "us-east-1"
}