from boto3.dynamodb.conditions import Key, Attr
from decimal import Decimal
from datetime import date
import hashlib
import boto3
import time
import json
import os

def make_query(query, cache):
    athena_client = boto3.client('athena')

    if cache:
        dynamo_client = boto3.resource('dynamodb')
        
        query_hash = hashlib.sha256(query.encode()).hexdigest()
        table = dynamo_client.Table(os.environ["QUERY_TABLE_DYNAMO"])
        result = table.get_item(Key={'hash': query_hash})
        
        # cache hit
        if 'Item' in result:
            return {
                "query_execution_id": result["Item"]["query_execution_id"]
            }
    
    # There is no Lambda trigger, when the query terminates
    def poll_status(qei):
        while True:
            result = athena_client.get_query_execution(QueryExecutionId = qei)
            state = result['QueryExecution']['Status']['State']

            if state == 'SUCCEEDED':
                return result
            elif state == 'FAILED':
                return result

            time.sleep(1)

    response = athena_client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={
            'Database': os.environ["DATABASE_PACKETS"]
        },
        ResultConfiguration={
            'OutputLocation': 's3://' + os.environ["BUCKET_QUERY"] + '/'
        }
    )

    query_execution_id = response["QueryExecutionId"]
    result = poll_status(query_execution_id)

    if result['QueryExecution']['Status']['State'] == 'SUCCEEDED':
        if cache:
            table = dynamo_client.Table(os.environ["QUERY_TABLE_DYNAMO"])
            table.put_item(
                Item={
                    'hash': query_hash,
                    'query_execution_id': query_execution_id,
                    'timestamp': Decimal(str(time.time()))
                }
            )
        return {
            "query_execution_id": query_execution_id
        }
    
    return {
        'message': 'database error'
    }



def netquack_api_post_query(event, context):
    # extract parameters
    date_from = event["date_from"]
    date_to = event["date_to"]
    latitude_from = event["latitude_from"]
    latitude_to = event["latitude_to"]
    longitude_from = event["longitude_from"]
    longitude_to = event["longitude_to"]
    frequency = event["frequency"]
    bitrate = event["bitrate"]
    modulation = event["modulation"]
    data = event["data"]
    
    coordinates = [latitude_from, longitude_from, latitude_to, longitude_to]
    
    # input validation
    for char in data:
        if char not in "0123456789abcdef%_":
            return {
                'message': 'bad pattern string'
            }
    if date_from:
        try:
            date(*map(int, date_from.split('-')))
        except:
            return {
                'message': 'bad date format'
            }
    if date_to:
        try:
            date(*map(int, date_to.split('-')))
        except:
            return {
                'message': 'bad date format'
            }
    if any(coordinates):
        if not all(coordinates):
            return {
                'message': 'missing coordinates'
            }
        try:
            latitude_from = float(latitude_from)
            longitude_from = float(longitude_from)
            latitude_to = float(latitude_to)
            longitude_to = float(longitude_to)
            if latitude_from <= -90 or latitude_from >= 90 or \
               latitude_to <= -90 or latitude_to >= 90 or \
               longitude_from < -180 or longitude_from > 180 or \
               longitude_to < -180 or longitude_to > 180 or \
               latitude_from >= latitude_to or \
               longitude_from >= longitude_to:
                raise ValueError
        except:
            return {
                'message': 'bad coordinates'
            }
    if modulation and modulation not in ['OOK', 'FSK2', 'GFSK']:
        return {
            'message': 'bad modulation'
        }
    if frequency:
        try:
            frequency = float(frequency)
            if frequency < 0 or frequency > 3000:
                raise ValueError
        except:
            return {
                'message': 'bad frequency'
            }
    if bitrate:
        try:
            bitrate = float(bitrate)
            if bitrate < 0 or bitrate > 5000:
                raise ValueError
        except:
            return {
                'message': 'bad bitrate'
            }
    
    # date validation: a big mess
    if not date_from:  # in case of no date provided, use last week 
        date_from_t = date.fromordinal(date.today().toordinal()-7)
        date_to_t = date.fromordinal(date.today().toordinal()-1)
        date_from = str(date_from_t)
        date_to = str(date_to_t)
    else:              # if one or both dates are provided, ensure they are in one week range
        if date_to == "":
            date_to = date_from
        date_from_t = date(*map(int, date_from.split('-')))
        date_to_t = date(*map(int, date_to.split('-')))
        difference = date_to_t.toordinal() - date_from_t.toordinal()
        if difference > 7:
            return {
                'message': 'date range too large'
            }
        if difference < 0:
            return {
                'message': 'negative date range'
            }
        if date_from_t > date.today() or date_to_t > date.today():
            return {
                'message': 'dates in the future'
            }

    # prepare query and execute <3
    clauses = []
    if data:
        clauses.append("data LIKE '{}'".format(data))
    clauses.append("date BETWEEN date '{}' AND date '{}'".format(date_from, date_to))
    if all(coordinates):
        clauses.append("latitude BETWEEN {} AND {}".format(latitude_from, latitude_to))
        clauses.append("longitude BETWEEN {} AND {}".format(longitude_from, longitude_to))
    if frequency:
        clauses.append("carrierFreq BETWEEN {} AND {}".format(frequency-1, frequency+1))
    if bitrate:
        clauses.append("bitRate BETWEEN {} AND {}".format(bitrate-1, bitrate+1))
    if modulation:
        clauses.append("modulation = '{}'".format(modulation))
    sql_query = "SELECT * FROM packets WHERE " + " AND ".join(clauses)
    
    # use cache only for queries in the past
    result = make_query(sql_query, date_to_t < date.today())

    return result

