#!/bin/sh

# generate ZIP archives for Lambda functions
cd Lambda
for function in ./*; do
  cd $function
  zip -r $function.zip *
  mv $function.zip ../$function.zip
  cd ..
done
cd ..

# deploy backend
terraform init
echo yes | terraform apply
echo { > config.json
echo "  \"API_URL\":   \"$(terraform output api_url)\","   >> config.json
echo "  \"MQTT_HOST\": \"$(terraform output mqtt_host)\"," >> config.json
echo "  \"MQTT_PORT\": \"$(terraform output mqtt_port)\""  >> config.json
echo } >> config.json

