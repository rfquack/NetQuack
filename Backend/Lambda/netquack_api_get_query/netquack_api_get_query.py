import boto3
import json
import os

def netquack_api_get_query(event, context):
    query_execution_id = event["query_execution_id"]
    next_token = event["next_token"]

    athena_client = boto3.client('athena')
    try:
        if next_token:
            response = athena_client.get_query_results(QueryExecutionId=query_execution_id,
                                                       NextToken=next_token,
                                                       MaxResults=100)
        else:
            response = athena_client.get_query_results(QueryExecutionId=query_execution_id,
                                                       MaxResults=100)
    except:
        return {
            'message': 'wrong parameters'
        }
    
    # Athena response is a mess...  it is converted in a csv style list
    unprocessed_rows = response["ResultSet"]["Rows"]
    result = []
    for row in unprocessed_rows:
        this_row = []
        data = row["Data"]
        for column in data:
            this_row.append(column["VarCharValue"])
        result.append(",".join(this_row))
    
    return {
        "query_execution_id": query_execution_id,
        "next_token": response["NextToken"] if "NextToken" in response else "",
        "result": result
    }
