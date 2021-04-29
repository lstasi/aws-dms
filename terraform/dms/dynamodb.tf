resource "aws_dynamodb_table" "movies" {
  name      = "Movies"
  hash_key  = "Year"
  range_key = "Title"

  attribute {
    name = "Title"
    type = "N"
  }
  attribute {
    name = "Year"
    type = "N"
  }

  tags = {
    project = "dms"
  }
}
resource "aws_dynamodb_table_item" "movie-item" {
  table_name = aws_dynamodb_table.movies.name
  hash_key   = aws_dynamodb_table.movies.hash_key

  item = <<ITEM
{
'year': {"N": "1999"},
'title': {"S": "Matrix"},
'info': {
    'plot': {"S": "The Matrix"},
    'rating': {"N": "5"}
}
ITEM
}