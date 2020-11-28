AWS_REGION = "eu-west-1"

BUCKET_PACKETS = "netquack-packets-"
BUCKET_QUERY   = "netquack-packets-query-"

KINESIS_STREAM_POLICY              = "KinesisStreamPolicy"
KINESIS_FIREHOSE_POLICY            = "KinesisFirehosePolicy"
LAMBDA_DYNAMO_POLICY               = "LambdaDynamoPolicy"

ATHENA_ROLE            = "athena-role"
ATHENA_S3_DYNAMO_ROLE  = "athena-s3-dynamo-role"
FIREHOSE_ROLE          = "firehose-delivery-role"
IOT_KINESIS_ROLE       = "iot-to-kinesis-role"
LAMBDA_DYNAMO_ROLE     = "lambda-dynamo"
LAMBDA_DYNAMO_IOT_ROLE = "lambda-dynamo-iot"
LAMBDA_DYNAMO_S3_ROLE  = "lambda-dynamo-s3"
LAMBDA_S3_ROLE         = "lambda-s3-role"

DATABASE_PACKETS       = "netquack"
DATABASE_PACKETS_GLUE  = "netquack_glue"
TABLE_PACKETS          = "packets"
GLUE_PACKETS           = "kinesis"

DONGLE_TABLE_DYNAMO = "dongle"
QUERY_TABLE_DYNAMO  = "query"

DAILY_SCHEDULE_LAMBDA           = "daily_schedule"
TRANSFORMATION_LAMBDA           = "transformation"
NETQUACK_API_GET_DONGLE_LAMBDA  = "netquack_api_get_dongle"
NETQUACK_API_POST_DONGLE_LAMBDA = "netquack_api_post_dongle"
NETQUACK_API_PUT_DONGLE_LAMBDA  = "netquack_api_put_dongle"
NETQUACK_API_GET_QUERY_LAMBDA   = "netquack_api_get_query"
NETQUACK_API_POST_QUERY_LAMBDA  = "netquack_api_post_query"

STREAM_PACKETS = "netquack-packets-stream"

DONGLE_SHELL_POLICY = "DongleShellPolicy"
ADMIN_POLICY        = "AdminPolicy"
DONGLE_TYPE         = "Dongle"
SHELL_TYPE          = "Shell"

NETQUACK_API_NAME = "netquack-api"
