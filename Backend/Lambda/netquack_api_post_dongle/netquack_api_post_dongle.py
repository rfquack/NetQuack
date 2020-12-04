from boto3.dynamodb.conditions import Key, Attr
from decimal import Decimal
import hashlib
import boto3
import json
import time
import re
import os

def netquack_api_post_dongle(event, context):
    name = event["name"]
    latitude = event["latitude"]
    longitude = event["longitude"]
    
    # input validation (name)
    if not re.match(r"^[0-9a-zA-Z-_]+$", name) or len(name) > 32 or name == "any" or "Shell" in name:
        return {
            "message": "bad dongle name"
        }
    
    # input validation (latitude and longitude)
    try:
        latitude = float(latitude)
        longitude = float(longitude)
        if latitude <= -90 or latitude >= 90 or longitude < -180 or longitude > 180:
            raise ValueError
    except:
        return {
            "message": "bad coordinates"
        }
    
    # register dongle
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(os.environ["DONGLE_TABLE_DYNAMO"])
    if table.query(KeyConditionExpression=Key("name").eq(name))["Count"] != 0:
        return {
            "message": "dongle name already used"
        }
    
    iot = boto3.client("iot")
    iot.create_thing(thingName=f"{name}",
                     thingTypeName="Dongle")
    iot.create_thing(thingName=f"{name}Shell",
                     thingTypeName="Shell",
                     attributePayload={"attributes": {"dongle": name}})
    certificate = iot.create_keys_and_certificate(setAsActive=True)
    iot.attach_policy(policyName="DongleShellPolicy", target=certificate["certificateArn"])
    iot.attach_thing_principal(thingName=f"{name}", principal=certificate["certificateArn"])
    iot.attach_thing_principal(thingName=f"{name}Shell", principal=certificate["certificateArn"])
    
    # a token to let the user modify the dongle
    enchilada = certificate["keyPair"]["PrivateKey"].encode()
    dongleKey = hashlib.sha256(enchilada).hexdigest()
    
    table.put_item(
       Item={
            "name": name,
            "latitude": Decimal(str(latitude)),
            "longitude": Decimal(str(longitude)),
            "dongleKey": dongleKey,
            "from_time": Decimal(str(time.time()))
        }
    )

    # this is required for user to connect and it is equal for all devices
    rootCA = "-----BEGIN CERTIFICATE-----\n" \
"MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF\n" \
"ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6\n" \
"b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL\n" \
"MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv\n" \
"b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj\n" \
"ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM\n" \
"9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw\n" \
"IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6\n" \
"VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L\n" \
"93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm\n" \
"jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC\n" \
"AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA\n" \
"A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI\n" \
"U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs\n" \
"N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv\n" \
"o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU\n" \
"5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy\n" \
"rqXRfboQnoZsG4q5WTP468SQvvG5\n" \
"-----END CERTIFICATE-----\n"
    
    return {
            "certificatePem": certificate["certificatePem"],
            "publicKey": certificate["keyPair"]["PublicKey"],
            "privateKey": certificate["keyPair"]["PrivateKey"],
            "rootCA": rootCA,
            "dongleKey": dongleKey
        }

