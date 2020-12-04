from boto3.dynamodb.conditions import Key, Attr
from decimal import Decimal
import boto3
import json
import time
import re
import os

def netquack_api_put_dongle(event, context):
    name = event["name"]
    latitude = event["latitude"]
    longitude = event["longitude"]
    dongleKey = event["dongleKey"]
    
    # input validation
    try:
        latitude = float(latitude)
        longitude = float(longitude)
        if latitude <= -90 or latitude >= 90 or longitude < -180 or longitude > 180:
            raise ValueError
    except:
        return {
            "message": "bad coordinates"
        }
    
    # update dongle
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(os.environ["DONGLE_TABLE_DYNAMO"])
    query = table.query(KeyConditionExpression=Key("name").eq(name),
                        FilterExpression="attribute_not_exists(to_time)")
    
    if query["Count"] == 0:
        return {
            "message": "dongle does not exist"
        }
    
    if query["Items"][0]["dongleKey"] != dongleKey:
        return {
            "message": "wrong dongle key"
        }
    
    from_time = query["Items"][0]["from_time"]
    to_time = time.time()
    table.update_item(Key={"name": name, "from_time": from_time},
                      UpdateExpression="set to_time = :time",
                      ExpressionAttributeValues={
                          ":time": Decimal(str(to_time))
                      })
    
    table.put_item(Item={
        "name": name,
        "latitude": Decimal(str(latitude)),
        "longitude": Decimal(str(longitude)),
        "dongleKey": query["Items"][0]["dongleKey"],
        "from_time": Decimal(str(to_time))
    })
    
    return {
            "message": "dongle updated"
        }

