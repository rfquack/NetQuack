from urllib.parse import urlencode
import requests
import click
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



@click.group()
def netquack():
    pass



@netquack.command()
@click.option('--name', type=str, required=True)
@click.option('--latitude', type=float, required=True)
@click.option('--longitude', type=float, required=True)
def add_dongle(name, latitude, longitude):
    params = {
        'name': name,
        'latitude': latitude,
        'longitude': longitude
    }
    url = f"{API_URL}/dongle?{urlencode(params)}"
    response = requests.post(url)
    text = json.loads(response.text)
    if 'message' in text:
        click.echo("Error: {}".format(text['message']))
        return
        
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
    
    click.echo("Dongle created successfully. The following files have been created:")
    click.echo("- rfquack_certificates.h")
    click.echo("- {}-certificate.pem.crt".format(name))
    click.echo("- {}-public.pem.key".format(name))
    click.echo("- {}-private.pem.key".format(name))
    click.echo("- rootCA.pem")
    click.echo("")
    click.echo("In order to use your dongle, copy rfquack_certificates.h into src/ and put these definitions into main.cpp:")
    click.echo('\t#define RFQUACK_UNIQ_ID "{}"'.format(name))
    click.echo("\t#define RFQUACK_TOPIC_PREFIX RFQUACK_UNIQ_ID")
    click.echo('\t#define RFQUACK_MQTT_BROKER_HOST "{}"'.format(MQTT_HOST))
    click.echo("\t#define RFQUACK_MQTT_BROKER_PORT {}".format(MQTT_PORT))
    click.echo("\t#define RFQUACK_MQTT_BROKER_SSL")
    click.echo("")
    click.echo("In order to interact with your dongle from the shell, use this command:")
    click.echo("\trfquack mqtt -i {0}Shell -H {1} -P {2} -a rootCA.pem -c {0}-certificate.pem.crt -k {0}-private.pem.key".format(name, MQTT_HOST, MQTT_PORT))
    click.echo("")
    click.echo("If you want to update your dongle later, use this token to authenticate.")
    click.echo("It has been obtained by running 'sha512sum {}-private.pem.key'".format(name))
    click.echo("\t{}".format(text['dongleKey']))



@netquack.command()
@click.option('--name', type=str, required=True)
@click.option('--latitude', type=float, required=True)
@click.option('--longitude', type=float, required=True)
@click.option('--key', type=str, required=True)
def update_dongle(name, latitude, longitude, key):
    params = {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'dongleKey': key
    }
    url = f"{API_URL}/dongle?{urlencode(params)}"
    response = requests.put(url)
    text = json.loads(response.text)
    click.echo(text['message'])



@netquack.command()
@click.option('--date_from', type=str)
@click.option('--date_to', type=str)
@click.option('--latitude_from', type=float)
@click.option('--latitude_to', type=float)
@click.option('--longitude_from', type=float)
@click.option('--longitude_to', type=float)
@click.option('--data', type=str)
@click.option('--frequency', type=float)
@click.option('--bitrate', type=float)
@click.option('--modulation', type=click.Choice(['OOK', 'FSK2', 'GFSK']))
def query(date_from, date_to, latitude_from, latitude_to, longitude_from, longitude_to, data, frequency, bitrate, modulation):
    params = {k: v for k, v in {
        'date_from': date_from,
        'date_to': date_to,
        'latitude_from': latitude_from,
        'latitude_to': latitude_to,
        'longitude_from': longitude_from,
        'longitude_to': longitude_to,
        'data': data,
        'frequency': frequency,
        'bitrate': bitrate,
        'modulation': modulation
    }.items() if v is not None}
    url = f"{API_URL}/query?{urlencode(params)}"
    response = requests.post(url)
    text = json.loads(response.text)
    if 'message' in text:
        click.echo("Error: {}".format(text['message']))
        return
    elif 'query_execution_id' in text:
        query_execution_id = text['query_execution_id']
        next_token = ""
        QUIT = False
        while not QUIT:
            params = {
                'query_execution_id': query_execution_id,
                'next_token': next_token
            }
            url = f"{API_URL}/query?{urlencode(params)}"
            response = requests.get(url)
            text = json.loads(response.text)
            query_execution_id = text['query_execution_id']
            next_token = text['next_token']
            result = text['result']
            
            # results are in csv: first row contains fields
            if next_token == "" and len(result) == 1:
                click.echo("No result")
                return
            
            for packet in result:
                click.echo(packet)
            
            if next_token == "" or not click.confirm("Do you want to show more results?"):
                QUIT = True
    else:
        print(text)



if __name__ == '__main__':
    netquack()
