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
  git_branch_name          = "master"

  name        = "Staff-Device-Logging"
  prefix_name = module.label.id
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn
}

module "pttp-infrastructure-ci-pipeline-dns-dhcp" {
  source                   = "./modules/ci-pipeline"
  service_name             = "core"
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "staff-device-dns-dhcp-infrastructure"
  git_branch_name          = "main"

  name        = "Staff-Device-DNS-DHCP-Infrastructure"
  prefix_name = "${module.label.id}-dns-dhcp"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn
}

module "pttp-infrastructure-ci-pipeline-dhcp-container" {
  source                   = "./modules/ci-pipeline"
  service_name             = "core"
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "staff-device-dhcp-server"
  git_branch_name          = "main"

  name        = "Staff-Device-DHCP-Server"
  prefix_name = "${module.label.id}-kea-server"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn

  privileged_mode = true
}

module "pttp-infrastructure-ci-pipeline-dns-dhcp-admin-container" {
  source                   = "./modules/ci-pipeline"
  service_name             = "core"
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "staff-device-dns-dhcp-admin"
  git_branch_name          = "main"

  name        = "Staff-Device-Admin-Portal"
  prefix_name = "${module.label.id}-admin"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn

  privileged_mode = true
}

module "pttp-infrastructure-ci-pipeline-dns-container" {
  source                   = "./modules/ci-pipeline"
  service_name             = "core"
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "staff-device-dns-server"
  git_branch_name          = "main"

  name        = "Staff-Device-DNS-Server"
  prefix_name = "${module.label.id}-dns-server"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn

  privileged_mode = true
}

module "pttp-infrastructure-ci-pipeline-metric-aggregation-container" {
  source                   = "./modules/ci-pipeline"
  service_name             = ""
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "staff-infrastructure-metric-aggregation-server"
  git_branch_name          = "main"

  name        = "${module.label.id}-metric-aggregation-server-pipeline"
  prefix_name = "${module.label.id}-aggregation"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn

  privileged_mode = true
}

module "pttp-infrastructure-ci-pipeline-infra-monitoring-alerting" {
  source                   = "./modules/ci-pipeline"
  service_name             = "core"
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "staff-infrastructure-monitoring"
  git_branch_name          = "main"

  name        = "${module.label.id}-ima-core-pipeline"
  prefix_name = "${module.label.id}-ima"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn
}

module "pttp-infrastructure-ci-pipeline-grafana-config" {
  source                   = "./modules/ci-pipeline"
  service_name             = ""
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "staff-infrastructure-monitoring-datasource-config"
  git_branch_name          = "main"

  name        = "${module.label.id}-grafana-config--pipeline"
  prefix_name = "${module.label.id}-grafana-config"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn
}

module "pttp-infrastructure-ci-pipeline-infra-monitoring-alerting-snmpexporter" {
  source                   = "./modules/ci-pipeline"
  service_name             = "core"
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "staff-infrastructure-monitoring-snmpexporter"
  git_branch_name          = "main"

  name        = "${module.label.id}-snmp-core-pipeline"
  prefix_name = "${module.label.id}-snmp"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn
}

module "pttp-public-key-infrastructure-pipeline" {
  source                   = "./modules/ci-pipeline"
  service_name             = "core"
  github_organisation_name = "ministryofjustice"
  github_repo_name         = "staff-infrastructure-certificate-services"
  git_branch_name          = "main"

  name        = "${module.label.id}-pki-core-pipeline"
  prefix_name = "${module.label.id}-pki"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  dev_assume_role_arn            = var.dev_assume_role_arn
  pre_production_assume_role_arn = var.pre_production_assume_role_arn
  production_assume_role_arn     = var.production_assume_role_arn
}

module "log-forward" {
  source          = "./modules/log-forwarding"
  destination_arn = var.kinesis_destination_arn
  prefix_name     = module.label.id
}

module "cloudtrail" {
  source                                       = "./modules/cloudtrail"
  enable_cloudtrail_log_shipping_to_cloudwatch = var.enable_cloudtrail_log_shipping_to_cloudwatch
  prefix                                       = module.label.id
  region                                       = data.aws_region.current_region.id
  tags                                         = module.label.tags
}

module "vpc_flow_logs" {
  source = "./modules/vpc_flow_logs"
  prefix = module.label.id
  region = data.aws_region.current_region.id
  tags   = module.label.tags
  vpc_id = module.vpc.vpc_id
}
