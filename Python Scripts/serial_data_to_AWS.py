import boto3
from botocore.client import Config
import json
from datetime import date
import serial

# Setting up Serial port for UART data from STM32
ser = serial.Serial("/dev/ttyAMA0")
ser.baudrate = 9600

# AWS Bucket Information
ACCESS_KEY_ID = ''
ACCESS_SECRET_KEY = ''
BUCKET_NAME = 'plant-sensor-data-storage-plant.ai'

# Specify file name based off the date
today = date.today()
today_file = str(today) + '.txt'

# Reading current sensor values from Serial bus
curr_moisture = ser.read(2)
curr_temp = ser.read(2)
curr_humidity = ser.read(2)

ser.close()


# Make JSON file with values
values = {'current_state': {'moisture': curr_moisture, 'temperature': curr_temp, 'humidity': curr_humidity}}
with open(today_file, 'w') as outfile:
    json.dump(values, outfile)

# Open file data with binary encoding
data = open(today_file, 'rb')

# Upload to bucket
s3 = boto3.resource(
    's3',
    aws_access_key_id=ACCESS_KEY_ID,
    aws_secret_access_key=ACCESS_SECRET_KEY,
    config=Config(signature_version='s3v4')
)
s3.Bucket(BUCKET_NAME).put_object(Key=today_file, Body=data)

print ("Done")
