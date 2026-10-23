terraform {
  # 1.10+ is required for S3 native state locking (use_lockfile).
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.69.1"
    }
  }

  # Partial backend configuration. bucket, key and region are supplied at
  # init time so the same code can target any account/environment:
  #
  #   terraform init -backend-config=backend.hcl
  #
  # use_lockfile enables S3 native state locking (a .tflock object written
  # next to the state with S3 conditional writes). No DynamoDB table needed;
  # the dynamodb_table argument is deprecated since Terraform 1.11.
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
