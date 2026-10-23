################################################################################
# ECR repository for application images
#  - IMMUTABLE tags: a tag can never be re-pointed, which is what makes
#    "build once, promote by digest" auditable
#  - scan on push (basic scanning); enable Inspector enhanced scanning at the
#    registry level for continuous CVE re-evaluation
#  - lifecycle policy keeps storage cost bounded
################################################################################

resource "aws_ecr_repository" "app" {
  name                 = "${var.project}/podinfo"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.ecr_untagged_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.ecr_untagged_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the last ${var.ecr_max_tagged_images} tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_max_tagged_images
        }
        action = { type = "expire" }
      }
    ]
  })
}
