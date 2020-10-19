variable "is-production" {
  type    = bool
  default = "true"
}

variable "owner-email" {
  type    = string
  default = "emile.swarts@digital.justice.gov.uk"
}

variable "dev_assume_role_arn" {
  type = string
}

variable "pre_production_assume_role_arn" {
  type = string
}

variable "production_assume_role_arn" {
  type = string
}

variable "enable_cloudtrail_log_shipping_to_cloudwatch" {
  type = bool
}

variable "log_forward_config" {
  type = object({
    production = object({
      destination_arn = string
      log_groups = list(string)
    }),
    pre_production = object({
      destination_arn = string
      log_groups = list(string)
    }),
    development = object({
      destination_arn = string
      log_groups = list(string)
    })
  })
}
