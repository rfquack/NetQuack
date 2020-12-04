from boto3.dynamodb.conditions import Key, Attr
from google.protobuf.message import Message
from urllib.parse import unquote_plus
from collections import Counter
from datetime import date
from time import time
from math import log
import rfquack_pb2
import base64
import boto3
import uuid
import json
import os



def get_enthropy(data):
    chars = set(data)
    probs = [data.count(ch)/len(data) for ch in chars]
    enthropy = -sum([p*log(p)/log(2) for p in probs])
    return enthropy

def transformation(event, context):
    locations = dict()  # cache for dongle locations
    output = []
    
    for record in event['records']:
        message = json.loads(base64.b64decode(record['data']))

        # retrieve topic, payload and timestamp
        topic = message['topic']
        payload = base64.b64decode(message['payload'])
        timestamp = message['timestamp']
        # deserialize the packet
        pb_packet = rfquack_pb2.__dict__.get("Packet")()
        pb_packet.ParseFromString(payload)
        # simple junk filter
        #if get_enthropy(pb_packet.data.hex()) <= 1.1: continue
        # extract dongle and location
        dongle = topic.split('/')[0]
        if dongle in locations:
            latitude = locations[dongle][0]
            longitude = locations[dongle][1]
        else:
            dynamodb = boto3.resource('dynamodb')
            table = dynamodb.Table('dongle')
            result = table.query(KeyConditionExpression=Key("name").eq(dongle),
                                 FilterExpression="attribute_not_exists(to_time)")
            # should never happen
            if result["Count"] == 0:
                output.append({
                          'recordId': record['recordId'],
                          'result': 'ProcessingFailed',
                          'data': record['data']
                })
                continue
            # extract location
            latitude = float(result['Items'][0]['latitude'])
            longitude = float(result['Items'][0]['longitude'])
            # save in cache
            locations[dongle] = (latitude, longitude)
        # extract fields
        # a packet from RFQuack has .data .rxRadio .millis .repeat .bitRate .carrierFreq .modulation .syncWords .frequencyDeviation .RSSI .model
        # in S3 we need data, timestamp, location, frequency, bitrate, modulation, syncWords, frequency deviation, RSSI, model, dongle
        packet = dict()
        packet['data'] = pb_packet.data.hex()
        packet['timestamp'] = timestamp
        packet['latitude'] = latitude
        packet['longitude'] = longitude
        packet['carrierFreq'] = pb_packet.carrierFreq
        packet['bitRate'] = pb_packet.bitRate
        packet['modulation'] = pb_packet.modulation
        packet['syncWords'] = pb_packet.syncWords.hex()
        packet['frequencyDeviation'] = pb_packet.frequencyDeviation
        packet['RSSI'] = pb_packet.RSSI
        packet['model'] = pb_packet.model
        packet['dongle'] = dongle

        output.append({
                          'recordId': record['recordId'],
                          'result': 'Ok',
                          'data': base64.b64encode( (json.dumps(packet) + '\n').encode() )
                      })
    
    return {
        'records': output
    }
