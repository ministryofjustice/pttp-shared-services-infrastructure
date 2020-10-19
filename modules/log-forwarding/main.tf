resource "aws_cloudwatch_log_subscription_filter" "production" {
  count = length(var.log_forward_config.production.log_groups)

  name            = element(var.log_forward_config.production.log_groups, count.index)
  log_group_name  = element(var.log_forward_config.production.log_groups, count.index)
  filter_pattern  = ""
  destination_arn = var.log_forward_config.production.destination_arn
}

resource "aws_cloudwatch_log_subscription_filter" "pre_production" {
  count = length(var.log_forward_config.pre_production.log_groups)

  name            = element(var.log_forward_config.pre_production.log_groups, count.index)
  log_group_name  = element(var.log_forward_config.pre_production.log_groups, count.index)
  filter_pattern  = ""
  destination_arn = var.log_forward_config.pre_production.destination_arn
}

resource "aws_cloudwatch_log_subscription_filter" "development" {
  count = length(var.log_forward_config.development.log_groups)

  name            = element(var.log_forward_config.development.log_groups, count.index)
  log_group_name  = element(var.log_forward_config.development.log_groups, count.index)
  filter_pattern  = ""
  destination_arn = var.log_forward_config.development.destination_arn
}
