/*
Cluster Logging
*/

data "aws_iam_policy_document" "cluster_logging_kms_key" {
  statement {
    actions = ["kms:*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    resources = ["*"]
  }

  statement {
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "logs.${data.aws_region.current.name}.amazonaws.com"
      ]
    }

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.cluster_log_group_name}" # have to interpolate/construct the ARN so we don't have a circular dependency
      ]
    }
  }
}


resource "aws_kms_key" "cluster_logging" {
  description             = "${local.cluster_name} cluster logging"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.cluster_logging_kms_key.json
}

resource "aws_kms_alias" "cluster_logging" {
  name          = "alias/${local.cluster_name}-cluster-logging"
  target_key_id = aws_kms_key.cluster_logging.key_id
}

/*
Cluster Resource Encryption
*/

data "aws_iam_policy_document" "cluster_resource_encryption" {
  statement {
    actions = ["kms:*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    resources = ["*"]
  }
}


resource "aws_kms_key" "cluster_resource_encryption" {
  description             = "${local.cluster_name} cluster resource encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.cluster_resource_encryption.json
}

resource "aws_kms_alias" "cluster_resource_encryption" {
  name          = "alias/${local.cluster_name}-cluster-resource-encryption"
  target_key_id = aws_kms_key.cluster_resource_encryption.key_id
}
