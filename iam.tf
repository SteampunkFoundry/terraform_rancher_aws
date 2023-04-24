data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
