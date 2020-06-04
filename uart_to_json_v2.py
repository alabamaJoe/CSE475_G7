import serial
import json
import numpy as np
from datetime import date
import boto3
from botocore.client import Config

# serial port for UART from stm32
ser = serial.Serial ("/dev/ttyS0") #Open named port
ser.baudrate = 115200

# AWS bucket info
ACCESS_KEY_ID = 'AKIA4ZKRBRTAJGLQTCIT'
ACCESS_SECRET_KEY = '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'
BUCKET_NAME = 'plant-sensor-data-storage-plant.ai'

data_file = 'data_plant.json'

# Initializing data array for temp, humid, moist
num = [6.9, 6.9, 6.9]
i = 0

while i < 3:
#     if i != 3:
    data_line = ser.readline()
    data_str = data_line.decode("utf-8")
    if len(data_str) > 1:
        num[i] = float(data_str[15:20])
    i += 1

curr_temp     = num[0]
curr_humidity = num[1]
curr_moisture = num[2]

# make json file with values
values = [{'temperature': curr_temp, 'humidity': curr_humidity, 'moisture': curr_moisture}]
with open(data_file, 'w') as outfile:
    json.dump(values, outfile)


# Open file data with binary encoding
data_b = open(data_file, 'rb')

# Upload to bucket
s3 = boto3.resource(
    's3',
    aws_access_key_id = ACCESS_KEY_ID,
    aws_secret_access_key = ACCESS_SECRET_KEY,
    config = Config(signature_version = 's3v4')
)

s3.Bucket(BUCKET_NAME).put_object(Key = data_file, Body = data_b, ACL='public-read', ContentType='text/plain')

print(values)
