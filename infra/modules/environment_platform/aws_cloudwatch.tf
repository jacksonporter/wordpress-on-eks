/*
Cluster Logging
*/

resource "aws_cloudwatch_log_group" "cluster" {
  name              = local.cluster_log_group_name
  retention_in_days = 1
  kms_key_id        = aws_kms_key.cluster_logging.arn
}
