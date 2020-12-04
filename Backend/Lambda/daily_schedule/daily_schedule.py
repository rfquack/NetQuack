from boto3.dynamodb.conditions import Attr
from datetime import date, timedelta
from decimal import Decimal
import boto3
import json
import time
import os

def daily_schedule(event, context):
    # create new partitions for today and tomorrow
    s3_client = boto3.client("s3")
    s3_client.put_object(Bucket=os.environ["BUCKET_PACKETS"], Key=f"date={date.today()}/")
    s3_client.put_object(Bucket=os.environ["BUCKET_PACKETS"], Key=f"date={date.today()+timedelta(days=1)}/")
    
    # update Athena partitions
    athena_client = boto3.client("athena")
    athena_client.start_query_execution(
        QueryString="MSCK REPAIR TABLE {}".format(os.environ["TABLE_PACKETS"]),
        QueryExecutionContext={
            'Database': os.environ["DATABASE_PACKETS"]
        },
        ResultConfiguration={
            'OutputLocation': 's3://' + os.environ["BUCKET_QUERY"] + '/'
        }
    )
    
    # remove queries that are not cached anymore
    table = boto3.resource("dynamodb").Table(os.environ["QUERY_TABLE_DYNAMO"])
    result = table.scan(FilterExpression=Attr('timestamp').lt(Decimal(time.time() - 3600*24*30)))
    for item in result['Items']:
        table.delete_item(Key={
            'hash': item['hash']
        })
    

