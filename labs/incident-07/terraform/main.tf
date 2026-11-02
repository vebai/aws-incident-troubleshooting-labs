# Separate least-privilege identity: preserve the shared Shop instance profile.
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "incident" {
  name_prefix        = "${var.project_prefix}-role-"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.incident.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ListBucket is needed to distinguish a missing S3 key (404) from an
# authorisation failure (403). Both object keys are confined to this lab.
data "aws_iam_policy_document" "bootstrap" {
  statement {
    sid     = "ReadOnlyLabBootstrapKeys"
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.catalog_bucket}/${var.catalog_key}",
      "arn:aws:s3:::${var.catalog_bucket}/shop.env"
    ]
  }
  statement {
    sid       = "IdentifyMissingLabKeys"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.catalog_bucket}"]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = [var.catalog_key, "shop.env"]
    }
  }
}

resource "aws_iam_role_policy" "bootstrap" {
  name   = "Incident07BootstrapRead"
  role   = aws_iam_role.incident.id
  policy = data.aws_iam_policy_document.bootstrap.json
}

resource "aws_iam_instance_profile" "incident" {
  name_prefix = "${var.project_prefix}-profile-"
  role        = aws_iam_role.incident.name
}

data "aws_caller_identity" "current" {}

# Separate resources: do not modify the existing Shop ASG or launch template.
# On purpose, EC2-only ASG health checks prevent an unbounded replacement loop.
resource "aws_launch_template" "incident" {
  name_prefix            = "${var.project_prefix}-lt-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile { name = aws_iam_instance_profile.incident.name }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  user_data = base64encode(templatefile("${path.module}/bootstrap.sh.tftpl", {
    bucket = var.catalog_bucket
    key    = var.inject_failure ? "shop.env" : "${var.catalog_key}"
  }))
  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_prefix}-instance", Project = var.project_prefix }
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "incident" {
  name_prefix               = "${var.project_prefix}-asg-"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 240
  vpc_zone_identifier       = [var.subnet_id]
  launch_template {
    id      = aws_launch_template.incident.id
    version = aws_launch_template.incident.latest_version
  }
  # Replacement occurs only after explicitly opting in to an instance refresh.
  # With this isolated ASG, at most one instance runs at a time.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
      max_healthy_percentage = 100
      instance_warmup        = 30
    }
  }
  tag {
    key                 = "Name"
    value               = "${var.project_prefix}-instance"
    propagate_at_launch = true
  }
  tag {
    key                 = "Project"
    value               = var.project_prefix
    propagate_at_launch = true
  }
}
