variable "project" {
  description = "Project prefix; must match the main stack."
  type        = string
  default     = "eks-gitops"
}

variable "region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "eu-west-1"
}

variable "github_repository" {
  description = "GitHub repository (owner/name) allowed to assume the Terraform role."
  type        = string
  default     = "rsk071216-stack/aws-eks-gitops-platform"
}

variable "github_environments" {
  description = "GitHub environments whose jobs may assume the role. Configure required reviewers on them."
  type        = list(string)
  default     = ["aws-plan", "aws-platform"]
}

variable "create_github_oidc_provider" {
  description = "Set to false if the account already has the token.actions.githubusercontent.com OIDC provider."
  type        = bool
  default     = true
}

variable "github_role_policy_arns" {
  description = <<-EOT
    Managed policies attached to the Terraform deployment role. Creating VPCs,
    EKS clusters and IAM roles needs broad rights; AdministratorAccess is the
    pragmatic default for a sandbox account. In a client landing zone, replace
    it with a scoped policy plus an IAM permissions boundary.
  EOT
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
