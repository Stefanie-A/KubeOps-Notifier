terraform {
  backend "s3" {
    bucket         = "remote-bucket-902839103466-us-east-1-an"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "remote-lock"
    encrypt        = true
  }
}
