resource "aws_dynamodb_table" "movies" {
  name         = "Movies"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "year"
  range_key    = "title"

  attribute {
    name = "title"
    type = "S"
  }
  attribute {
    name = "year"
    type = "N"
  }

  tags = {
    project = "dms"
  }
}