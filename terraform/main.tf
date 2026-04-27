terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

module "vpc" {
  source          = "./module/vpc"
  cluster_name    = var.cluster_name
  vpc_cidr        = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

module "eks" {
  source             = "./module/eks"
  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.vpc.private_subnets
  node_instance_type = var.node_instance_type
  node_min           = var.node_min
  node_max           = var.node_max
  node_desired       = var.node_desired
}

module "addons" {
  source           = "./module/addons"
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca       = module.eks.cluster_ca

  depends_on = [module.eks, data.aws_eks_cluster_auth.this]
}
