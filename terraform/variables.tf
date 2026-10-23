variable "project" {
  description = "Short project name, used as a prefix for every resource."
  type        = string
  default     = "eks-gitops"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project))
    error_message = "project must be 3-21 chars, lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  description = "Environment name (one shared cluster hosts the qa and prod namespaces in this reference setup)."
  type        = string
  default     = "platform"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "extra_tags" {
  description = "Additional tags applied to every resource (cost center, owner, ...)."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR block. A /16 leaves room for three /20 private subnets (pods use VPC IPs with the VPC CNI)."
  type        = string
  default     = "10.42.0.0/16"
}

variable "single_nat_gateway" {
  description = "true = one shared NAT gateway (cheap, single-AZ egress dependency). false = one NAT gateway per AZ (production-grade HA, ~3x NAT cost)."
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Ship VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version."
  type        = string
  default     = "1.35"
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Restrict to your office/VPN egress IPs."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Instance types for the managed node group (several types improve Spot availability)."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_group_size" {
  description = "Managed node group scaling configuration."
  type = object({
    min     = number
    max     = number
    desired = number
  })
  default = {
    min     = 2
    max     = 5
    desired = 3
  }
}

variable "cluster_admin_principal_arns" {
  description = "IAM role/user ARNs granted cluster-admin through EKS access entries (e.g. an SSO admin role)."
  type        = list(string)
  default     = []
}

variable "qa_editor_principal_arns" {
  description = "IAM role ARNs granted edit rights scoped to the podinfo-qa namespace only (e.g. a developer SSO role)."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Workload
# ---------------------------------------------------------------------------

variable "workload_namespaces" {
  description = "Namespaces that run the example workload. Each gets a Pod Identity association for the podinfo service account."
  type        = list(string)
  default     = ["podinfo-qa", "podinfo-prod"]
}

variable "ecr_untagged_expiry_days" {
  description = "Days after which untagged ECR images are expired."
  type        = number
  default     = 7
}

variable "ecr_max_tagged_images" {
  description = "Number of tagged images to retain in ECR."
  type        = number
  default     = 50
}
