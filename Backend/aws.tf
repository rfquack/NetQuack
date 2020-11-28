// Prerequisites:
// - An AWS account
// - AWS CLI installed
// - AWS credentials configured
//
// Run bash genesis.sh
//
// Notes:
// - AWS Region set in credentials should match the one set in terraform.tfvars
// - For some reason Terraform could upload a Lambda function and then complain it already exists: run "terraform import aws_lambda_function.FUNCTION_NAME FUNCTION_NAME" and rerun "bash genesis.sh"

// ---------------------------------------------------------------------------------------------------- //

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.AWS_REGION
}

// ---------------------------------------------------------------------------------------------------- //

// Variables
data "aws_caller_identity" "current" {}
variable "AWS_REGION" {}

variable "BUCKET_PACKETS" {}
variable "BUCKET_QUERY" {}

variable "KINESIS_STREAM_POLICY" {}
variable "KINESIS_FIREHOSE_POLICY" {}
variable "LAMBDA_DYNAMO_POLICY" {}

variable "ATHENA_ROLE" {}
variable "ATHENA_S3_DYNAMO_ROLE" {}
variable "FIREHOSE_ROLE" {}
variable "IOT_KINESIS_ROLE" {}
variable "LAMBDA_DYNAMO_ROLE" {}
variable "LAMBDA_DYNAMO_IOT_ROLE" {}
variable "LAMBDA_DYNAMO_S3_ROLE" {}
variable "LAMBDA_S3_ROLE" {}

variable "DATABASE_PACKETS" {}
variable "DATABASE_PACKETS_GLUE" {}
variable "TABLE_PACKETS" {}
variable "GLUE_PACKETS" {}

variable "DONGLE_TABLE_DYNAMO" {}
variable "QUERY_TABLE_DYNAMO" {}

variable "DAILY_SCHEDULE_LAMBDA" {}
variable "TRANSFORMATION_LAMBDA" {}
variable "NETQUACK_API_GET_DONGLE_LAMBDA" {}
variable "NETQUACK_API_POST_DONGLE_LAMBDA" {}
variable "NETQUACK_API_PUT_DONGLE_LAMBDA" {}
variable "NETQUACK_API_GET_QUERY_LAMBDA" {}
variable "NETQUACK_API_POST_QUERY_LAMBDA" {}

variable "STREAM_PACKETS" {}

variable "DONGLE_SHELL_POLICY" {}
variable "ADMIN_POLICY" {}
variable "DONGLE_TYPE" {}
variable "SHELL_TYPE" {}

variable "NETQUACK_API_NAME" {}

// ---------------------------------------------------------------------------------------------------- //

// S3
resource "aws_s3_bucket" "bucket_packets" {
  bucket_prefix = var.BUCKET_PACKETS
  acl           = "private"
}

resource "aws_s3_bucket" "bucket_query" {
  bucket_prefix = var.BUCKET_QUERY
  acl           = "private"
}

// ---------------------------------------------------------------------------------------------------- //

// IAM (policies)
resource "aws_iam_policy" "kinesis_stream_policy" {
  name        = var.KINESIS_STREAM_POLICY
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "glue:GetTable",
        "glue:GetTableVersion",
        "glue:GetTableVersions"
      ],
      "Resource": [
        "arn:aws:glue:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:catalog",
        "arn:aws:glue:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:database/${var.DATABASE_PACKETS}",
        "arn:aws:glue:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:table/${var.DATABASE_PACKETS}/${var.GLUE_PACKETS}"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.bucket_packets.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.bucket_packets.bucket}/*"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration"
      ],
      "Resource": "arn:aws:lambda:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:function:${var.TRANSFORMATION_LAMBDA}:$LATEST"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:kms:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
      ],
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "s3.${var.AWS_REGION}.amazonaws.com"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:s3:arn": [
            "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*"
          ]
        }
      }
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/${var.STREAM_PACKETS}:log-stream:*"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:ListShards"
      ],
      "Resource": "arn:aws:kinesis:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:kms:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
      ],
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "kinesis.${var.AWS_REGION}.amazonaws.com"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:kinesis:arn": "arn:aws:kinesis:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "kinesis_firehose_policy" {
  name        = var.KINESIS_FIREHOSE_POLICY
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
      ],
      "Resource": "arn:aws:firehose:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:deliverystream/${var.STREAM_PACKETS}"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_dynamo_policy" {
  name        = var.LAMBDA_DYNAMO_POLICY
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem"
      ],
      "Resource": "arn:aws:dynamodb:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:table/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "arn:aws:lambda:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:function:*"
    }
  ]
}
EOF
}

// ---------------------------------------------------------------------------------------------------- //

// IAM (roles)
resource "aws_iam_role" "athena_role" {
  name = var.ATHENA_ROLE

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "apigateway.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "athena_s3_dynamo_role" {
  name = var.ATHENA_S3_DYNAMO_ROLE

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "firehose_role" {
  name = var.FIREHOSE_ROLE

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${data.aws_caller_identity.current.account_id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role" "iot_to_kinesis_role" {
  name = var.IOT_KINESIS_ROLE

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "iot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_dynamo_role" {
  name = var.LAMBDA_DYNAMO_ROLE

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_dynamo_iot_role" {
  name = var.LAMBDA_DYNAMO_IOT_ROLE

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_dynamo_s3_role" {
  name = var.LAMBDA_DYNAMO_S3_ROLE

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_s3_role" {
  name = var.LAMBDA_S3_ROLE

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// ---------------------------------------------------------------------------------------------------- //

// IAM (built-in policies)
data "aws_iam_policy" "AmazonS3FullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy" "AmazonAPIGatewayInvokeFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
}

data "aws_iam_policy" "AmazonAthenaFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

data "aws_iam_policy" "AWSLambdaExecute" {
  arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy" "AmazonDynamoDBFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

data "aws_iam_policy" "AWSIoTFullAccess" {
  arn = "arn:aws:iam::aws:policy/AWSIoTFullAccess"
}

data "aws_iam_policy" "AmazonKinesisFirehoseFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"
}

// ---------------------------------------------------------------------------------------------------- //

// IAM (policies to roles)
resource "aws_iam_role_policy_attachment" "athena_role_attach_1" {
  role       = aws_iam_role.athena_role.name
  policy_arn = data.aws_iam_policy.AmazonS3FullAccess.arn
}

resource "aws_iam_role_policy_attachment" "athena_role_attach_2" {
  role       = aws_iam_role.athena_role.name
  policy_arn = data.aws_iam_policy.AmazonAPIGatewayInvokeFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "athena_role_attach_3" {
  role       = aws_iam_role.athena_role.name
  policy_arn = data.aws_iam_policy.AmazonAthenaFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "athena_role_attach_4" {
  role       = aws_iam_role.athena_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaExecute.arn
}

resource "aws_iam_role_policy_attachment" "athena_role_attach_5" {
  role       = aws_iam_role.athena_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "athena_s3_dynamo_role_attach_1" {
  role       = aws_iam_role.athena_s3_dynamo_role.name
  policy_arn = data.aws_iam_policy.AmazonS3FullAccess.arn
}

resource "aws_iam_role_policy_attachment" "athena_s3_dynamo_role_attach_2" {
  role       = aws_iam_role.athena_s3_dynamo_role.name
  policy_arn = data.aws_iam_policy.AmazonDynamoDBFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "athena_s3_dynamo_role_attach_3" {
  role       = aws_iam_role.athena_s3_dynamo_role.name
  policy_arn = data.aws_iam_policy.AmazonAthenaFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "athena_s3_dynamo_role_attach_4" {
  role       = aws_iam_role.athena_s3_dynamo_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "firehose_role_attach_1" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.kinesis_stream_policy.arn
}

resource "aws_iam_role_policy_attachment" "iot_to_kinesis_role_attach_1" {
  role       = aws_iam_role.iot_to_kinesis_role.name
  policy_arn = aws_iam_policy.kinesis_firehose_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_attach_1" {
  role       = aws_iam_role.lambda_dynamo_role.name
  policy_arn = data.aws_iam_policy.AmazonDynamoDBFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_attach_2" {
  role       = aws_iam_role.lambda_dynamo_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_attach_3" {
  role       = aws_iam_role.lambda_dynamo_role.name
  policy_arn = aws_iam_policy.lambda_dynamo_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_attach_4" {
  role       = aws_iam_role.lambda_dynamo_role.name
  policy_arn = data.aws_iam_policy.AmazonKinesisFirehoseFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_iot_role_attach_1" {
  role       = aws_iam_role.lambda_dynamo_iot_role.name
  policy_arn = data.aws_iam_policy.AmazonDynamoDBFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_iot_role_attach_2" {
  role       = aws_iam_role.lambda_dynamo_iot_role.name
  policy_arn = data.aws_iam_policy.AWSIoTFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_iot_role_attach_3" {
  role       = aws_iam_role.lambda_dynamo_iot_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_s3_role_attach_1" {
  role       = aws_iam_role.lambda_dynamo_s3_role.name
  policy_arn = data.aws_iam_policy.AmazonS3FullAccess.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_s3_role_attach_2" {
  role       = aws_iam_role.lambda_dynamo_s3_role.name
  policy_arn = data.aws_iam_policy.AmazonDynamoDBFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_s3_role_attach_3" {
  role       = aws_iam_role.lambda_dynamo_s3_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "lambda_s3_role_attach_1" {
  role       = aws_iam_role.lambda_s3_role.name
  policy_arn = data.aws_iam_policy.AmazonS3FullAccess.arn
}

resource "aws_iam_role_policy_attachment" "lambda_s3_role_attach_2" {
  role       = aws_iam_role.lambda_s3_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaExecute.arn
}

// ---------------------------------------------------------------------------------------------------- //

// Athena
resource "aws_athena_database" "database_packets" {
  name   = var.DATABASE_PACKETS
  bucket = aws_s3_bucket.bucket_query.bucket
}

// Terraform can not execute queries through Athena directly: a workaround is executing them through the CLI
resource "null_resource" "table_packets" {
  provisioner "local-exec" {
    command = "aws athena start-query-execution --query-string \"${templatefile("athena.sql", {
      DATABASE = aws_athena_database.database_packets.name,
      TABLE    = var.TABLE_PACKETS,
      BUCKET   = aws_s3_bucket.bucket_packets.bucket
    })}\" --output json --query-execution-context Database=${aws_athena_database.database_packets.id} --result-configuration \"OutputLocation=s3://${aws_s3_bucket.bucket_query.bucket}/\""
  }
}

// ---------------------------------------------------------------------------------------------------- //

// DynamoDB
resource "aws_dynamodb_table" "dongle-table" {
  name           = var.DONGLE_TABLE_DYNAMO
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "name"
  range_key      = "from_time"

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "from_time"
    type = "N"
  }
}

resource "aws_dynamodb_table" "query-table" {
  name           = var.QUERY_TABLE_DYNAMO
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "hash"

  attribute {
    name = "hash"
    type = "S"
  }
}

// ---------------------------------------------------------------------------------------------------- //

// Lambda
resource "aws_lambda_function" "daily_schedule" {
  filename      = "Lambda/${var.DAILY_SCHEDULE_LAMBDA}.zip"
  function_name = var.DAILY_SCHEDULE_LAMBDA
  role          = aws_iam_role.athena_s3_dynamo_role.arn
  handler       = "${var.DAILY_SCHEDULE_LAMBDA}.${var.DAILY_SCHEDULE_LAMBDA}"
  runtime       = "python3.8"
  memory_size   = 256
  timeout       = 60
  environment {
    variables = {
      DATABASE_PACKETS    = var.DATABASE_PACKETS
      TABLE_PACKETS       = var.TABLE_PACKETS
      BUCKET_PACKETS      = aws_s3_bucket.bucket_packets.bucket
      BUCKET_QUERY        = aws_s3_bucket.bucket_query.bucket
      QUERY_TABLE_DYNAMO  = var.QUERY_TABLE_DYNAMO
      DONGLE_TABLE_DYNAMO = var.DONGLE_TABLE_DYNAMO
      DONGLE_TYPE         = var.DONGLE_TYPE
      SHELL_TYPE          = var.SHELL_TYPE
      DONGLE_SHELL_POLICY = var.DONGLE_SHELL_POLICY
      ADMIN_POLICY        = var.ADMIN_POLICY
    }
  }
}

resource "aws_lambda_function" "transformation" {
  filename      = "Lambda/${var.TRANSFORMATION_LAMBDA}.zip"
  function_name = var.TRANSFORMATION_LAMBDA
  role          = aws_iam_role.lambda_dynamo_role.arn
  handler       = "${var.TRANSFORMATION_LAMBDA}.${var.TRANSFORMATION_LAMBDA}"
  runtime       = "python3.8"
  memory_size   = 512
  timeout       = 60
  environment {
    variables = {
      DATABASE_PACKETS    = var.DATABASE_PACKETS
      TABLE_PACKETS       = var.TABLE_PACKETS
      BUCKET_PACKETS      = aws_s3_bucket.bucket_packets.bucket
      BUCKET_QUERY        = aws_s3_bucket.bucket_query.bucket
      QUERY_TABLE_DYNAMO  = var.QUERY_TABLE_DYNAMO
      DONGLE_TABLE_DYNAMO = var.DONGLE_TABLE_DYNAMO
      DONGLE_TYPE         = var.DONGLE_TYPE
      SHELL_TYPE          = var.SHELL_TYPE
      DONGLE_SHELL_POLICY = var.DONGLE_SHELL_POLICY
      ADMIN_POLICY        = var.ADMIN_POLICY
    }
  }
}

resource "aws_lambda_function" "netquack_api_get_dongle" {
  filename      = "Lambda/${var.NETQUACK_API_GET_DONGLE_LAMBDA}.zip"
  function_name = var.NETQUACK_API_GET_DONGLE_LAMBDA
  role          = aws_iam_role.lambda_dynamo_role.arn
  handler       = "${var.NETQUACK_API_GET_DONGLE_LAMBDA}.${var.NETQUACK_API_GET_DONGLE_LAMBDA}"
  runtime       = "python3.8"
  memory_size   = 128
  timeout       = 30
  environment {
    variables = {
      DATABASE_PACKETS    = var.DATABASE_PACKETS
      TABLE_PACKETS       = var.TABLE_PACKETS
      BUCKET_PACKETS      = aws_s3_bucket.bucket_packets.bucket
      BUCKET_QUERY        = aws_s3_bucket.bucket_query.bucket
      QUERY_TABLE_DYNAMO  = var.QUERY_TABLE_DYNAMO
      DONGLE_TABLE_DYNAMO = var.DONGLE_TABLE_DYNAMO
      DONGLE_TYPE         = var.DONGLE_TYPE
      SHELL_TYPE          = var.SHELL_TYPE
      DONGLE_SHELL_POLICY = var.DONGLE_SHELL_POLICY
      ADMIN_POLICY        = var.ADMIN_POLICY
    }
  }
}

resource "aws_lambda_function" "netquack_api_post_dongle" {
  filename      = "Lambda/${var.NETQUACK_API_POST_DONGLE_LAMBDA}.zip"
  function_name = var.NETQUACK_API_POST_DONGLE_LAMBDA
  role          = aws_iam_role.lambda_dynamo_iot_role.arn
  handler       = "${var.NETQUACK_API_POST_DONGLE_LAMBDA}.${var.NETQUACK_API_POST_DONGLE_LAMBDA}"
  runtime       = "python3.8"
  memory_size   = 128
  timeout       = 30
  environment {
    variables = {
      DATABASE_PACKETS    = var.DATABASE_PACKETS
      TABLE_PACKETS       = var.TABLE_PACKETS
      BUCKET_PACKETS      = aws_s3_bucket.bucket_packets.bucket
      BUCKET_QUERY        = aws_s3_bucket.bucket_query.bucket
      QUERY_TABLE_DYNAMO  = var.QUERY_TABLE_DYNAMO
      DONGLE_TABLE_DYNAMO = var.DONGLE_TABLE_DYNAMO
      DONGLE_TYPE         = var.DONGLE_TYPE
      SHELL_TYPE          = var.SHELL_TYPE
      DONGLE_SHELL_POLICY = var.DONGLE_SHELL_POLICY
      ADMIN_POLICY        = var.ADMIN_POLICY
    }
  }
}

resource "aws_lambda_function" "netquack_api_put_dongle" {
  filename      = "Lambda/${var.NETQUACK_API_PUT_DONGLE_LAMBDA}.zip"
  function_name = var.NETQUACK_API_PUT_DONGLE_LAMBDA
  role          = aws_iam_role.lambda_dynamo_role.arn
  handler       = "${var.NETQUACK_API_PUT_DONGLE_LAMBDA}.${var.NETQUACK_API_PUT_DONGLE_LAMBDA}"
  runtime       = "python3.8"
  memory_size   = 128
  timeout       = 30
  environment {
    variables = {
      DATABASE_PACKETS    = var.DATABASE_PACKETS
      TABLE_PACKETS       = var.TABLE_PACKETS
      BUCKET_PACKETS      = aws_s3_bucket.bucket_packets.bucket
      BUCKET_QUERY        = aws_s3_bucket.bucket_query.bucket
      QUERY_TABLE_DYNAMO  = var.QUERY_TABLE_DYNAMO
      DONGLE_TABLE_DYNAMO = var.DONGLE_TABLE_DYNAMO
      DONGLE_TYPE         = var.DONGLE_TYPE
      SHELL_TYPE          = var.SHELL_TYPE
      DONGLE_SHELL_POLICY = var.DONGLE_SHELL_POLICY
      ADMIN_POLICY        = var.ADMIN_POLICY
    }
  }
}

resource "aws_lambda_function" "netquack_api_get_query" {
  filename      = "Lambda/${var.NETQUACK_API_GET_QUERY_LAMBDA}.zip"
  function_name = var.NETQUACK_API_GET_QUERY_LAMBDA
  role          = aws_iam_role.athena_s3_dynamo_role.arn
  handler       = "${var.NETQUACK_API_GET_QUERY_LAMBDA}.${var.NETQUACK_API_GET_QUERY_LAMBDA}"
  runtime       = "python3.8"
  memory_size   = 512
  timeout       = 60
  environment {
    variables = {
      DATABASE_PACKETS    = var.DATABASE_PACKETS
      TABLE_PACKETS       = var.TABLE_PACKETS
      BUCKET_PACKETS      = aws_s3_bucket.bucket_packets.bucket
      BUCKET_QUERY        = aws_s3_bucket.bucket_query.bucket
      QUERY_TABLE_DYNAMO  = var.QUERY_TABLE_DYNAMO
      DONGLE_TABLE_DYNAMO = var.DONGLE_TABLE_DYNAMO
      DONGLE_TYPE         = var.DONGLE_TYPE
      SHELL_TYPE          = var.SHELL_TYPE
      DONGLE_SHELL_POLICY = var.DONGLE_SHELL_POLICY
      ADMIN_POLICY        = var.ADMIN_POLICY
    }
  }
}

resource "aws_lambda_function" "netquack_api_post_query" {
  filename      = "Lambda/${var.NETQUACK_API_POST_QUERY_LAMBDA}.zip"
  function_name = var.NETQUACK_API_POST_QUERY_LAMBDA
  role          = aws_iam_role.athena_s3_dynamo_role.arn
  handler       = "${var.NETQUACK_API_POST_QUERY_LAMBDA}.${var.NETQUACK_API_POST_QUERY_LAMBDA}"
  runtime       = "python3.8"
  memory_size   = 512
  timeout       = 60
  environment {
    variables = {
      DATABASE_PACKETS    = var.DATABASE_PACKETS
      TABLE_PACKETS       = var.TABLE_PACKETS
      BUCKET_PACKETS      = aws_s3_bucket.bucket_packets.bucket
      BUCKET_QUERY        = aws_s3_bucket.bucket_query.bucket
      QUERY_TABLE_DYNAMO  = var.QUERY_TABLE_DYNAMO
      DONGLE_TABLE_DYNAMO = var.DONGLE_TABLE_DYNAMO
      DONGLE_TYPE         = var.DONGLE_TYPE
      SHELL_TYPE          = var.SHELL_TYPE
      DONGLE_SHELL_POLICY = var.DONGLE_SHELL_POLICY
      ADMIN_POLICY        = var.ADMIN_POLICY
    }
  }
}

// ---------------------------------------------------------------------------------------------------- //

// Glue
resource "aws_glue_catalog_database" "database_packets_glue" {
  name = var.DATABASE_PACKETS_GLUE
}

resource "aws_glue_catalog_table" "glue_packets" {
  name          = var.GLUE_PACKETS
  database_name = var.DATABASE_PACKETS

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location          = "s3://${aws_s3_bucket.bucket_query.bucket}/"
    input_format      = "org.apache.hadoop.mapred.TextInputFormat"
    output_format     = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed        = false
    number_of_buckets = 0

    ser_de_info {
      name                  = "filler"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "paths" = "bitrate,carrierfreq,data,date,dongle,frequencydeviation,latitude,longitude,model,modulation,rssi,syncwords,timestamp"
      }
    }

    columns {
      name = "timestamp"
      type = "string"
    }
    
    columns {
      name = "latitude"
      type = "float"
    }
    
    columns {
      name = "longitude"
      type = "float"
    }
    
    columns {
      name = "carrierfreq"
      type = "float"
    }
    
    columns {
      name = "bitrate"
      type = "float"
    }
    
    columns {
      name = "modulation"
      type = "string"
    }
    
    columns {
      name = "syncwords"
      type = "string"
    }
    
    columns {
      name = "frequencydeviation"
      type = "float"
    }
    
    columns {
      name = "rssi"
      type = "float"
    }
    
    columns {
      name = "model"
      type = "string"
    }
    
    columns {
      name = "dongle"
      type = "string"
    }
    
    columns {
      name = "data"
      type = "string"
    }
    
    columns {
      name = "date"
      type = "date"
    }

    parameters = {
      classification = "json"
    }
  }
}

// ---------------------------------------------------------------------------------------------------- //

// Kinesis Firehose
resource "aws_kinesis_firehose_delivery_stream" "stream_packets" {
  name        = var.STREAM_PACKETS
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket_packets.arn

    prefix = "date=!{timestamp:yyyy}-!{timestamp:MM}-!{timestamp:dd}/"
    error_output_prefix = "!{firehose:error-output-type}/date=!{timestamp:yyyy}-!{timestamp:MM}-!{timestamp:dd}/"
    buffer_size = 128
    buffer_interval = 900
    
    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.transformation.arn}:$LATEST"
        }
        
        parameters {
          parameter_name = "BufferSizeInMBs"
          parameter_value = 3
        }
       
        parameters {
          parameter_name = "BufferIntervalInSeconds"
          parameter_value = 900
        }
      }
    }
    
    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_table.glue_packets.database_name
        role_arn      = aws_iam_role.firehose_role.arn
        table_name    = aws_glue_catalog_table.glue_packets.name
      }
    }
  }
}

// ---------------------------------------------------------------------------------------------------- //

// IoT
data "aws_iot_endpoint" "mqtt_host" {
  endpoint_type = "iot:Data-ATS"
}

resource "aws_iot_topic_rule" "PacketSniffer" {
  name        = "PacketSniffer"
  description = "Sniff packets from connected dongles"
  enabled     = true
  sql         = "SELECT topic() AS topic, encode(*,'base64') AS payload, timestamp() AS timestamp FROM '+/out/get/+/rfquack_Packet/packet'"
  sql_version = "2016-03-23"

  firehose {
    delivery_stream_name    = aws_kinesis_firehose_delivery_stream.stream_packets.name
    role_arn                = aws_iam_role.iot_to_kinesis_role.arn
    separator               = "\n"
  }
}

resource "aws_iot_policy" "dongle_shell_policy" {
  name = var.DONGLE_SHELL_POLICY

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iot:Connect",
      "Resource": "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:client/$${iot:Connection.Thing.ThingName}"
    },
    {
      "Effect": "Allow",
      "Action": "iot:Subscribe",
      "Resource": [
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topicfilter/any/in/*",
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topicfilter/$${iot:Connection.Thing.ThingName}/in/*",
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topicfilter/*/out/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iot:Receive",
      "Resource": [
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topic/any/in/*",
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topic/$${iot:Connection.Thing.ThingName}/in/*",
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topic/$${iot:Connection.Thing.Attributes[dongle]}/out/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iot:Publish",
      "Resource": [
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topic/$${iot:Connection.Thing.ThingName}/out/*",
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topic/$${iot:Connection.Thing.Attributes[dongle]}/in/*",
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topic/any/in/set/ping/rfquack_VoidValue/ping"
      ]
    }
  ]
}
EOF
}

resource "aws_iot_policy" "admin_policy" {
  name = var.ADMIN_POLICY

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iot:Connect",
      "Resource": [
        "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:client/$${iot:Connection.Thing.ThingName}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iot:Subscribe",
      "Resource": "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topicfilter/*"
    },
    {
      "Effect": "Allow",
      "Action": "iot:Receive",
      "Resource": "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topic/*"
    },
    {
      "Effect": "Allow",
      "Action": "iot:Publish",
      "Resource": "arn:aws:iot:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:topic/*"
    }
  ]
}
EOF
}

resource "aws_iot_thing_type" "dongle_type" {
  name = var.DONGLE_TYPE
}

resource "aws_iot_thing_type" "shell_type" {
  name = var.SHELL_TYPE
}

// ---------------------------------------------------------------------------------------------------- //

// EventBridge
resource "aws_cloudwatch_event_rule" "daily_schedule_rule" {
  name        = "daily_schedule_rule"
  description = "Update Athena partitions and cache"

  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_schedule_rule.name
  arn       = aws_lambda_function.daily_schedule.arn
}

resource "aws_lambda_permission" "daily_schedule_permission" {
   statement_id  = "AllowEventBridgeInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.daily_schedule.function_name
   principal     = "events.amazonaws.com"
   source_arn    = aws_cloudwatch_event_rule.daily_schedule_rule.arn
}

// ---------------------------------------------------------------------------------------------------- //

// API Gateway
resource "aws_api_gateway_rest_api" "netquack_api" {
  name = var.NETQUACK_API_NAME

  body = templatefile("netquack-api.json", {
    AWS_REGION                      = var.AWS_REGION,
    AWS_USER                        = data.aws_caller_identity.current.account_id,
    NETQUACK_API_GET_DONGLE_LAMBDA  = var.NETQUACK_API_GET_DONGLE_LAMBDA,
    NETQUACK_API_POST_DONGLE_LAMBDA = var.NETQUACK_API_POST_DONGLE_LAMBDA,
    NETQUACK_API_PUT_DONGLE_LAMBDA  = var.NETQUACK_API_PUT_DONGLE_LAMBDA,
    NETQUACK_API_GET_QUERY_LAMBDA   = var.NETQUACK_API_GET_QUERY_LAMBDA,
    NETQUACK_API_POST_QUERY_LAMBDA  = var.NETQUACK_API_POST_QUERY_LAMBDA  
  })
}

resource "aws_api_gateway_deployment" "netquack_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.netquack_api.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "api_gateway_permission_get_dongle" {
   statement_id  = "AllowAPIGatewayInvokeGetDongle"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.netquack_api_get_dongle.function_name
   principal     = "apigateway.amazonaws.com"
   source_arn    = "${aws_api_gateway_rest_api.netquack_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_post_dongle" {
   statement_id  = "AllowAPIGatewayInvokePostDongle"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.netquack_api_post_dongle.function_name
   principal     = "apigateway.amazonaws.com"
   source_arn    = "${aws_api_gateway_rest_api.netquack_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_put_dongle" {
   statement_id  = "AllowAPIGatewayInvokePutDongle"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.netquack_api_put_dongle.function_name
   principal     = "apigateway.amazonaws.com"
   source_arn    = "${aws_api_gateway_rest_api.netquack_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_get_query" {
   statement_id  = "AllowAPIGatewayInvokeGetQuery"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.netquack_api_get_query.function_name
   principal     = "apigateway.amazonaws.com"
   source_arn    = "${aws_api_gateway_rest_api.netquack_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_post_query" {
   statement_id  = "AllowAPIGatewayInvokePostQuery"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.netquack_api_post_query.function_name
   principal     = "apigateway.amazonaws.com"
   source_arn    = "${aws_api_gateway_rest_api.netquack_api.execution_arn}/*/*/*"
}

// ---------------------------------------------------------------------------------------------------- //

// Output variables
output "api_url" {
  value = aws_api_gateway_deployment.netquack_api_deployment.invoke_url
}

output "mqtt_host" {
  value = data.aws_iot_endpoint.mqtt_host.endpoint_address
}

output "mqtt_port" {
  value = 8883
}
