resource "aws_ecr_repository" "ecr_repository" {
  name                 = "app-repo"
  image_tag_mutability = "IMMUTABLE"
  tags = {
    Name = "smart-receipt-ecr-repo"
  }
  lifecycle {
    prevent_destroy = false
  }

}