#!/bin/sh

terraform init
echo yes | terraform apply
echo { > config.json
echo "  \"API_URL\":   \"$(terraform output api_url)\","   >> config.json
echo "  \"MQTT_HOST\": \"$(terraform output mqtt_host)\"," >> config.json
echo "  \"MQTT_PORT\": \"$(terraform output mqtt_port)\""  >> config.json
echo } >> config.json

