data "local_file" "dockerfile" {
  filename = "${path.module}/app/Dockerfile"
}

locals {
  dockerfile_hash = sha256(file("${path.module}/app/Dockerfile"))
}

resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    command = <<EOT
      # ECR Authentication
      aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${module.container_repository.repository_url}
      
      # Build docker Image
      docker build --platform linux/amd64 -t ${module.container_repository.repository_url}:latest ./app
      
      # Tag image with repository name
      docker tag ${module.container_repository.repository_url}:latest ${module.container_repository.repository_url}:latest
      
      # Upload image to ECR
      docker push ${module.container_repository.repository_url}:latest
    EOT
  }
  triggers = {
    dockerfile_hash = local.dockerfile_hash
  }
  depends_on = [module.container_repository]
}
