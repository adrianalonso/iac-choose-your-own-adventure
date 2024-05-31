resource "aws_ecr_repository" "repository" {
  name                 = "${var.project_name}-repository"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  tags_all             = var.tags
}
