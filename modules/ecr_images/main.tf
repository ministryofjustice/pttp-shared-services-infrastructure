resource "aws_ecr_repository" "this" {
  for_each = [for name in var.repositories : name]
  name     = name
}
