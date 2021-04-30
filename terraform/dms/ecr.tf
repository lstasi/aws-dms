### AWS Docker Registry ###
resource "aws_ecr_repository" "dms" {
  name                 = "dms"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}