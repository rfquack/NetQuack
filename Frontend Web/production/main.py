from flask import Flask, render_template, request, send_file
import zipfile
import boto3
import requests
import json

try:
    with open("config.json", "r") as config:
        config = json.loads(config.read())
except:
    print("Configuration file missing! Run genesis.sh")
    exit()

API_URL = config["API_URL"]
MQTT_HOST = config["MQTT_HOST"]
MQTT_PORT = config["MQTT_PORT"]



app = Flask(__name__, static_folder='./build', static_url_path='/')

@app.route('/')
def index():
    return app.send_static_file('index.html')



@app.route("/api/register", methods=["POST"])
def register():
    form = json.loads(request.data)
    name = form['name']
    
    url = "{}/dongle?name={}&latitude={}&longitude={}".format(API_URL,
                                                              form['name'],
                                                              form['latitude'],
                                                              form['longitude']).replace("%", "%25")
    # special character % should be URL-encoded
    
    response = requests.post(url)
    text = json.loads(response.text)
    if 'message' in text:
        return text
        
    with open(f"{name}-certificate.pem.crt", "w") as outfile:
        outfile.write(text['certificatePem'])
    with open(f"{name}-public.pem.key", "w") as outfile:
        outfile.write(text['publicKey'])
    with open(f"{name}-private.pem.key", "w") as outfile:
        outfile.write(text['privateKey'])
    with open(f"rootCA.pem", "w") as outfile:
        outfile.write(text['rootCA'])
        
    str_certificatePem = ('"' + text['certificatePem'].replace('\n', '\\n" \\\n"'))[:-4] + ';'
    str_privateKey = ('"' + text['privateKey'].replace('\n', '\\n" \\\n"'))[:-4] + ';'
    str_rootCA = ('"' + text['rootCA'].replace('\n', '\\n" \\\n"'))[:-4] + ';'

    rfquack_certificates = \
"""/*
 * RFQuack is a versatile RF-hacking tool that allows you to sniff, analyze, and
 * transmit data over the air. Consider it as the modular version of the great
 *
 * Copyright (C) 2019 Trend Micro Incorporated
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 2 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 51
 * Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#ifndef rfquack_certificates_h
#define rfquack_certificates_h

// Amazon's root CA (this should be the same for everyone)
const char *SSL_CERT_CA = \\
{}

// The private key for your device
const char *SSL_CERT_PRIVATE = \\
{}

// The certificate for your device
const char *SSL_CERT_CRT = \\
{}

#endif
""".format(str_rootCA, str_privateKey, str_certificatePem)

    with open(f"rfquack_certificates.h", "w") as outfile:
        outfile.write(rfquack_certificates)
    
    zipFile = zipfile.ZipFile('dongle.zip', 'w', zipfile.ZIP_DEFLATED)
    zipFile.write(f"{name}-certificate.pem.crt")
    zipFile.write(f"{name}-public.pem.key")
    zipFile.write(f"{name}-private.pem.key")
    zipFile.write(f"rootCA.pem")
    zipFile.write(f"rfquack_certificates.h")
    zipFile.close()
    
    return send_file('dongle.zip', attachment_filename='dongle.zip')



@app.route("/api/update", methods=["POST"])
def update():
    form = json.loads(request.data)
    url = "{}/dongle?name={}&latitude={}&longitude={}&dongleKey={}".format(API_URL,
                                                                           form['name'],
                                                                           form['latitude'],
                                                                           form['longitude'],
                                                                           form['key']).replace("%", "%25")
    # special character % should be URL-encoded
    response = requests.put(url)
    text = json.loads(response.text)
    return text



if __name__ == "__main__":
    app.run()

