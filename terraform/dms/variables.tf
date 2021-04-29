variable "region" {
  type    = string
  default = "us-east-1"
}
variable "GITHUB_TOKEN" {
  type = string
  default = "$TF_VAR_GITHUB_TOKEN"
}
variable "REPO_URL" {
  type = string
  default = "TF_VAR_REPO_URL"
}