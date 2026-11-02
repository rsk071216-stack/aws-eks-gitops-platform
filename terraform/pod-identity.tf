################################################################################
# EKS Pod Identity
#
# Pod Identity replaces IRSA: no OIDC provider per cluster, no role trust
# policy edits per cluster, and the same IAM role can be reused across
# clusters. Credentials are delivered by the eks-pod-identity-agent add-on.
################################################################################

# AWS Load Balancer Controller -> manages ALBs/NLBs for Ingress/Service objects.
module "aws_lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.10.0"

  name = "${local.name}-aws-lbc"

  attach_aws_lb_controller_policy = true

  associations = {
    controller = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = local.tags
}

# Example application role, shared by qa and prod.
#
# Pod Identity adds session tags (kubernetes-namespace, kubernetes-service-account,
# eks-cluster-name, ...) to every assumed session. The policy uses them for
# attribute-based access control: a pod in podinfo-qa can only read
# /<cluster>/podinfo-qa/* parameters, a pod in podinfo-prod only
# /<cluster>/podinfo-prod/*. One role, no per-environment duplication,
# no cross-environment secret access.
module "podinfo_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.10.0"

  name = "${local.name}-podinfo"

  attach_custom_policy = true
  policy_statements = [
    {
      sid     = "ReadOwnNamespaceParameters"
      actions = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
      resources = [
        "arn:${data.aws_partition.current.partition}:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/$${aws:PrincipalTag/eks-cluster-name}/$${aws:PrincipalTag/kubernetes-namespace}/*",
      ]
    }
  ]

  associations = {
    for ns in var.workload_namespaces : ns => {
      cluster_name    = module.eks.cluster_name
      namespace       = ns
      service_account = "podinfo"
    }
  }

  tags = local.tags
}
