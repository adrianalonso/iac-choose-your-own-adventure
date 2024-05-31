data "local_file" "dockerfile" {
  filename = "${path.module}/app/Dockerfile"
}

locals {
  dockerfile_hash = sha256(file("${path.module}/app/Dockerfile"))
}

resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    command = <<EOT
      # Autenticarse con ECR
      aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.repo.repository_url}
      
      # Construir la imagen Docker
      docker build --platform linux/amd64 -t ${aws_ecr_repository.repo.repository_url}:latest ./app
      
      # Etiquetar la imagen
      docker tag ${aws_ecr_repository.repo.repository_url}:latest ${aws_ecr_repository.repo.repository_url}:latest
      
      # Subir la imagen a ECR
      docker push ${aws_ecr_repository.repo.repository_url}:latest
    EOT
  }
  triggers = {
    dockerfile_hash = local.dockerfile_hash
  }
  depends_on = [aws_ecr_repository.repo]
}
