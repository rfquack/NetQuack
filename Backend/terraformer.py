import re

# take as input an API definition exported from API Gateway and substitute the hard coded values with variables defined in terraform.tvars
# Usage: python3 terraformer.py < api_definition_file > netquack-api.json

while True:
    try:
        line = input()
        updated_line = re.sub(r'arn:aws:apigateway:(.*):lambda:path/2015-03-31/functions/arn:aws:lambda:(.*):(\d+):function:(.*)/invocations',
                              lambda match: 'arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${AWS_REGION}:${AWS_USER}:function:${' + match.group(4).upper().replace('-', '_') + '_LAMBDA}/invocations',
                              line)
        print(updated_line)
    except EOFError:
        exit()
