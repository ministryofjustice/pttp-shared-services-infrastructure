terraform {
  required_version = "> 0.12.0"

  backend "s3" {
    region     = "eu-west-2"
    bucket     = "pttp-global-bootstrap-pttp-infrastructure-tf-remote-state"
    key        = "terraform/v1/state"
    lock_table = "pttp-global-bootstrap-pttp-infrastructure-terrafrom-remote-state-lock-dynamo"
  }
}

provider "aws" {
  version = "~> 2.52"
}

data "aws_region" "current_region" {}

locals {
  cidr_block = "10.0.0.0/16"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.28.0"

  name = module.label.id

  enable_dns_hostnames = true
  enable_dns_support   = true
  cidr                 = local.cidr_block

  azs = [
    "${data.aws_region.current_region.id}a",
    "${data.aws_region.current_region.id}b",
    "${data.aws_region.current_region.id}c"
  ]

  private_subnets = [
    cidrsubnet(local.cidr_block, 8, 1),
    cidrsubnet(local.cidr_block, 8, 2),
    cidrsubnet(local.cidr_block, 8, 3)
  ]

  map_public_ip_on_launch = false
}



module "label" {
  source  = "cloudposse/label/null"
  version = "0.16.0"

  namespace = "pttp"
  stage     = terraform.workspace
  name      = "infrastructure"
  delimiter = "-"

  tags = {
    "business-unit" = "MoJO"
    "application"   = "pttp-shared-services-infrastructure",
    "is-production" = tostring(var.is-production),
    "owner"         = var.owner-email

    "environment-name" = "global"
    "source-code"      = "https://github.com/ministryofjustice/pttp-shared-services-infrastructure"
  }
}

module "pttp-infrastructure-ci-pipeline" {
  source                   = "./modules/ci-pipeline"
  service_name             = "core"
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "pttp-infrastructure"

  prefix_name = module.label.id
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn
  ost_vpc_id                     = var.ost_vpc_id
  ost_aws_account_id             = var.ost_aws_account_id
  ost_vpc_cidr_block             = var.ost_vpc_cidr_block
}
