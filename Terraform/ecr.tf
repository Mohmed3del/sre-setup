module "ECR" {
  source = "https://github.com/Mohmed3del/DevOps-project/tree/main/Terraform/Modules/ECR"
  ecr_repositories = {
    api-service = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      force_delete         = true

    }
    auth-service = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      force_delete         = true

    }
    image-service = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      force_delete         = true

    }
  }

}