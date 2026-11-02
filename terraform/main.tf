data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_caller_identity" "current" {

}

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  prefix = "${var.project}-${random_id.suffix.hex}"
}

resource "aws_vpc" "shop" {
  cidr_block           = "10.61.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${local.prefix}-vpc"
  }

}

resource "aws_internet_gateway" "shop" {
  vpc_id = aws_vpc.shop.id
  tags = {
    Name = "${local.prefix}-igw"
  }

}

resource "aws_subnet" "public" {

  count                   = 2
  vpc_id                  = aws_vpc.shop.id
  cidr_block              = cidrsubnet(aws_vpc.shop.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.prefix}-public-${count.index + 1}"
  }


}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.shop.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.shop.id
  }

}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name_prefix = "${local.prefix}-alb-"
  description = "HTTP only; restrict CIDRs before deployment"
  vpc_id      = aws_vpc.shop.id
  ingress {
    description = "Lab HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_security_group" "app" {
  name_prefix = "${local.prefix}-app-"
  description = "App reachable only from lab ALB"
  vpc_id      = aws_vpc.shop.id
  ingress {
    description     = "ALB to Shop port 8000"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_s3_bucket" "catalog" {
  bucket        = "${local.prefix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "catalog" {
  bucket                  = aws_s3_bucket.catalog.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "catalog" {
  bucket = aws_s3_bucket.catalog.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

  }

}

resource "aws_s3_bucket_versioning" "catalog" {
  bucket = aws_s3_bucket.catalog.id
  versioning_configuration {
    status = "Enabled"
  }

}

resource "aws_s3_object" "catalog" {
  bucket = aws_s3_bucket.catalog.id
  key    = "catalog.json"
  content = jsonencode({
    items = [{
      sku = "book-001", name = "Notebook", price = 8.5
      }
      , {
        sku = "book-002", name = "Pen", price = 1.5
      }
    ]
    }
  )
  content_type = "application/json"
  depends_on   = [aws_s3_bucket_versioning.catalog]
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

  }

}

resource "aws_iam_role" "app" {
  name               = "${local.prefix}-app-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "catalog_access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.catalog.arn}/catalog.json"]
  }

}

resource "aws_iam_role_policy" "catalog" {
  role   = aws_iam_role.app.name
  name   = "ShopCatalogAccess"
  policy = data.aws_iam_policy_document.catalog_access.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.prefix}-instance-profile"
  role = aws_iam_role.app.name
}

resource "aws_lb" "shop" {
  name               = "${substr(local.prefix, 0, 26)}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "shop" {
  name                 = "${substr(local.prefix, 0, 25)}-tg"
  port                 = 8000
  protocol             = "HTTP"
  vpc_id               = aws_vpc.shop.id
  target_type          = "instance"
  deregistration_delay = 10
  health_check {
    path                = "/healthz"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }


}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.shop.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shop.arn
  }

}

resource "aws_launch_template" "shop" {

  name_prefix   = "${local.prefix}-lt-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type
  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }

  vpc_security_group_ids = [aws_security_group.app.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {

    shop_code    = base64encode(file("${path.module}/../application/shop_app.py"))
    service_code = base64encode(file("${path.module}/../application/shop-app.service"))
    bucket       = aws_s3_bucket.catalog.bucket

    }
  ))
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "shop-app"
      Project = var.project
    }

  }


}

resource "aws_autoscaling_group" "shop" {

  name                      = "${local.prefix}-asg"
  vpc_zone_identifier       = aws_subnet.public[*].id
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 240
  target_group_arns         = [aws_lb_target_group.shop.arn]
  launch_template {
    id      = aws_launch_template.shop.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "shop-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.http, aws_iam_role_policy.catalog, aws_iam_role_policy_attachment.ssm]

}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {

  count               = var.enable_alarm ? 1 : 0
  alarm_name          = "${local.prefix}-alb-5xx"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.shop.arn_suffix
  }


}

