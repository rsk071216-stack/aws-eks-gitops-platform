output "state_bucket" {
  description = "Name of the Terraform state bucket (use in backend.hcl)."
  value       = aws_s3_bucket.state.id
}

output "github_terraform_role_arn" {
  description = "Store as the AWS_TERRAFORM_ROLE_ARN secret of the GitHub environment."
  value       = aws_iam_role.github_terraform.arn
}

output "backend_hcl" {
  description = "Ready-to-use content for terraform/backend.hcl."
  value       = <<-EOT
    bucket = "${aws_s3_bucket.state.id}"
    key    = "platform/terraform.tfstate"
    region = "${var.region}"
  EOT
}
