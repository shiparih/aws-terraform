provider "aws" {
  region = var.region
}

# Component : AWS Elasticahe Redis Clusture
# resource "aws_elasticache_cluster" "redis_cluster" {
#   cluster_id        = "rediscluster"
#   engine            = "redis"
#   node_type         = "cache.t3.micro"
#   num_cache_nodes   = 1
#   port              = 6379
#   apply_immediately = true
# }

# resource "aws_elasticache_parameter_group" "redispg" {
#   name   = "parameter-group"
#   family = "7.0.7"

# }

resource "aws_elasticache_replication_group" "redis_cluster" {
  replication_group_id          = "rediscluster"
  replication_group_description = "Example Redis cluster"
  node_type                     = "cache.t3.micro"
  port                          = 6379
  engine                        = "redis"
  engine_version                = "6.x"
  automatic_failover_enabled    = true
  # parameter_group_name          = aws_elasticache_parameter_group.redispg.name

  cluster_mode {
    replicas_per_node_group = 1
    num_node_groups         = 1
  }
}


resource "aws_s3_bucket" "lambdas3shilpi" {
  bucket = "lambdas3shilpi"
  tags = {
    Name = "POC"
  }
}

provider "archive" {}
data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "${path.module}/scripts/"
  output_path = "${path.module}/scripts/lambda_function.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_AmazonVPCFullAccess" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_AmazonElastiCacheFullAccess" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_AmazonS3FullAccess" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_CloudWatchFullAccess" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_lambda_function" "lambda_function" {
  filename      = "${path.module}/scripts/lambda_function.zip"
  function_name = "lambda_function"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  tags = {
    Name = "POC"
  }

  vpc_config {
    subnet_ids         = ["subnet-6bc12c00"]
    security_group_ids = ["sg-c7c907a3"]
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AmazonS3FullAccess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.lambdas3shilpi.arn
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket     = aws_s3_bucket.lambdas3shilpi.id
  depends_on = [aws_lambda_function.lambda_function]
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
}