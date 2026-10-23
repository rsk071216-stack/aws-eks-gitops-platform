################################################################################
# EKS cluster
#  - authentication_mode = "API": access entries only, no aws-auth ConfigMap
#  - EKS Pod Identity agent installed as a managed add-on (replaces IRSA)
#  - VPC CNI with prefix delegation (more pods per node) and network policy
#    enforcement so Kubernetes NetworkPolicy objects are actually enforced
################################################################################

locals {
  admin_access_entries = {
    for idx, arn in var.cluster_admin_principal_arns : "admin-${idx}" => {
      principal_arn = arn
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Least privilege example: developers can edit the qa namespace only.
  qa_editor_access_entries = {
    for idx, arn in var.qa_editor_principal_arns : "qa-editor-${idx}" => {
      principal_arn = arn
      policy_associations = {
        qa_edit = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["podinfo-qa"]
          }
        }
      }
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = local.name
  kubernetes_version = var.kubernetes_version

  # Public endpoint restricted by CIDR + private endpoint for in-VPC traffic.
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true
  access_entries                           = merge(local.admin_access_entries, local.qa_editor_access_entries)

  enabled_log_types = ["api", "audit", "authenticator"]

  addons = {
    coredns    = {}
    kube-proxy = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_groups = {
    general = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_group_size.min
      max_size     = var.node_group_size.max
      desired_size = var.node_group_size.desired

      labels = {
        "workload-class" = "general"
      }

      # IMDSv2 only, and pods cannot reach the node's instance profile
      # (hop limit 1). Pods get AWS credentials through Pod Identity instead.
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }
    }
  }

  tags = local.tags
}
