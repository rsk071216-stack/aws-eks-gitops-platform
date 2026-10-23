################################################################################
# VPC: 3 AZs, public subnets for load balancers, private subnets for nodes and
# pods, intra (no internet route) subnets for the EKS control-plane ENIs.
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = local.name
  cidr = var.vpc_cidr
  azs  = local.azs

  # 10.42.0.0/20, 10.42.16.0/20, 10.42.32.0/20 -> 4,091 IPs each for nodes + pods
  private_subnets = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  # 10.42.48.0/24 ... -> internet-facing ALBs, NAT gateways
  public_subnets = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]
  # 10.42.52.0/24 ... -> EKS control-plane cross-account ENIs
  intra_subnets = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  # Cost lever: one NAT gateway (~32 USD/month + data) vs one per AZ.
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Lock down the default security group / NACL created with every VPC.
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  enable_flow_log                                 = var.enable_vpc_flow_logs
  create_flow_log_cloudwatch_log_group            = var.enable_vpc_flow_logs
  create_flow_log_cloudwatch_iam_role             = var.enable_vpc_flow_logs
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 30

  # Subnet discovery tags for the AWS Load Balancer Controller.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
