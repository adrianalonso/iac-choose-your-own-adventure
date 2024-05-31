resource "aws_ecr_repository" "repo" {
  name                 = "repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}


output "repository_url" {
  value = aws_ecr_repository.repo.repository_url
}
