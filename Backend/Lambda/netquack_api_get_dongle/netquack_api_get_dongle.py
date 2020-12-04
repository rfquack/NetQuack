import boto3
import os

def netquack_api_get_dongle(event, context):
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(os.environ["DONGLE_TABLE_DYNAMO"])
    scan_kwargs = {
        'ProjectionExpression': "#name, #lat, #lon",
        'ExpressionAttributeNames': {"#name": "name",
                                     "#lat": "latitude",
                                     "#lon": "longitude"
         }
    }

    done = False
    start_key = None
    dongles = []
    while not done:
        if start_key:
            scan_kwargs['ExclusiveStartKey'] = start_key
        response = table.scan(**scan_kwargs)
        dongles.extend(response['Items'])
        start_key = response.get('LastEvaluatedKey', None)
        done = start_key is None

    return dongles

