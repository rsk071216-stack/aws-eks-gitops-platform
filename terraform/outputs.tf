output "region" {
  description = "AWS region."
  value       = var.region
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the control plane."
  value       = module.eks.cluster_version
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (nodes and pods)."
  value       = module.vpc.private_subnets
}

output "ecr_repository_url" {
  description = "ECR repository URL for application images."
  value       = aws_ecr_repository.app.repository_url
}

output "aws_lb_controller_role_arn" {
  description = "IAM role used by the AWS Load Balancer Controller via Pod Identity."
  value       = module.aws_lb_controller_pod_identity.iam_role_arn
}

output "podinfo_role_arn" {
  description = "IAM role used by the podinfo workload via Pod Identity."
  value       = module.podinfo_pod_identity.iam_role_arn
}

output "configure_kubectl" {
  description = "Command to point kubectl at the new cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

# GitOps bridge: cluster metadata that Argo CD ApplicationSets read from the
# cluster Secret annotations (see scripts/bootstrap-argocd.sh).
output "gitops_metadata" {
  description = "Cluster metadata consumed by Argo CD add-on ApplicationSets."
  value = {
    aws_cluster_name = module.eks.cluster_name
    aws_region       = var.region
    aws_vpc_id       = module.vpc.vpc_id
    aws_account_id   = data.aws_caller_identity.current.account_id
  }
}
