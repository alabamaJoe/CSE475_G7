# python3
#
# Copyright 2019 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Example using TF Lite to classify objects with the Raspberry Pi camera."""

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import argparse
import io
import time
import numpy as np
import json
import RPi.GPIO as GPIO
import boto3
import serial
import PIL

from botocore.client import Config
from datetime import date
from picamera import PiCamera
from time import sleep
from PIL import Image
from tflite_runtime.interpreter import Interpreter

# Number of seconds to wait before polling sensor data
TIME_CONST = 10

# AWS Bucket Information
ACCESS_KEY_ID = ''
ACCESS_SECRET_KEY = ''
BUCKET_NAME = 'plant-sensor-data-storage-plant.ai'

# Hardware setup
GPIO.setmode(GPIO.BCM)
GPIO.setup(2, GPIO.IN, pull_up_down=GPIO.PUD_UP)
camera = PiCamera()

# Setting up Serial port for UART data from STM32
ser = serial.Serial("/dev/ttyS0")
ser.baudrate = 115200

# Specify file name based off the date
data_file = 'data_plant.json'

# Functions
# Associates model and label files from the command
def load_labels(path):
  with open(path, 'r') as f:
    return {i: line.strip() for i, line in enumerate(f.readlines())}

# Pass in image size info and model
def set_input_tensor(interpreter, image):
  tensor_index = interpreter.get_input_details()[0]['index']
  input_tensor = interpreter.tensor(tensor_index)()[0]
  input_tensor[:, :] = image

# Take imagew input and run on the model. Outputs result
def classify_image(interpreter, image, top_k=1):
  """Returns a sorted array of classification results."""
  set_input_tensor(interpreter, image)
  interpreter.invoke()
  output_details = interpreter.get_output_details()[0]
  output = np.squeeze(interpreter.get_tensor(output_details['index']))

  # If the model is quantized (uint8 data), then dequantize the results
  if output_details['dtype'] == np.uint8:
    scale, zero_point = output_details['quantization']
    output = scale * (output - zero_point)

  ordered = np.argpartition(-output, top_k)
  return [(i, output[i]) for i in ordered[:top_k]]

# Callback function that uses the functions above to
# take a picture, run the image detection, and upload to AWS.
# Outputs a jpg of the taken photo and a json file
# with the output from the model.
def runML(channel):
  print("Beginning plant detection")
  # Extract file names from the command
  parser = argparse.ArgumentParser(
      formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  parser.add_argument(
      '--model', help='File path of .tflite file.', required=True)
  parser.add_argument(
      '--labels', help='File path of labels file.', required=True)
  args = parser.parse_args()

  labels = load_labels(args.labels)

  interpreter = Interpreter(args.model)
  interpreter.allocate_tensors()
  _, height, width, _ = interpreter.get_input_details()[0]['shape']

  # Start camera and take picture
  camera.start_preview()
  sleep(4)
  camera.capture('/home/pi/Desktop/cse475/image_plant.jpg')
  camera.stop_preview()
  image = Image.open('/home/pi/Desktop/cse475/image_plant.jpg').convert('RGB').resize((width, height),
                                                         Image.ANTIALIAS)
  
  # Run model on the taken picture and save result
  results = classify_image(interpreter, image)
  label_id, prob = results[0]
  data = [{"plantType": labels[label_id]}]
  
  # Write model detection result to plant.json
  with open('id_plant.json', 'w') as outfile:
    json.dump(data, outfile)
  
  
  
# Cropped image of above dimension 
# (It will not change orginal image) 
  image1 = Image.open("image_plant.jpg")
  
  w, h = image1.size
  
  # Setting the points for cropped image 
  left = w / 2 - h / 2 + h / 10
  top = h / 5
  right = w / 2 + h / 2 - h / 10
  bottom = h
  
  im1 = image1.crop((left, top, right, bottom)) 
  im1 = im1.save("image_plant_crop.jpg")
  
  # Open files with binary encoding
  plant_data = open('id_plant.json', 'rb')
  plant_image = open('image_plant.jpg', 'rb')
  plant_image_crop = open('image_plant_crop.jpg', 'rb')
  
  print(plant_data)
  # Upload jpg and json file to AWS Bucket
  s3 = boto3.resource(
       's3',
       aws_access_key_id=ACCESS_KEY_ID,
       aws_secret_access_key=ACCESS_SECRET_KEY,
       config=Config(signature_version='s3v4')
  )
  s3.Bucket(BUCKET_NAME).put_object(Key='id_plant.json', Body=plant_data, ACL='public-read', ContentType='text/plain')
  s3.Bucket(BUCKET_NAME).put_object(Key='image_plant.jpg', Body=plant_image_crop, ACL='public-read', ContentType='image/jpeg')
  #s3.Bucket(BUCKET_NAME).put_object(Key='image_plant_crop.jpg', Body=plant_image, ACL='public-read', ContentType='image/jpeg')
  print("Plant detection completed")
  
  
# Init callback
GPIO.add_event_detect(2, GPIO.FALLING, callback=runML, bouncetime=10000)

# Main loop
time = TIME_CONST
# while True:
#     if time == 0:
#         if len(ser.readline()) == 1: 
#             print("Grabbing sensor data to upload to AWS Bucket")
#             # Initializing data array for temp, humid, moist
#             i = 0
#             num = [6.9, 6.9, 6.9]
#             while i < 3 :
#                 data_line = ser.readline()
#                 data_str = data_line.decode("utf-8")
#                 if len(data_str) > 1:
#                     num[i] = float(data_str[15:20])
#                 i += 1
#             curr_temp     = num[0]
#             curr_humidity = num[1]
#             curr_moisture = num[2]
#             # make json file with values
#             values = [{'temperature': curr_temp, 'humidity': curr_humidity, 'moisture': curr_moisture}]
#             with open(data_file, 'w') as outfile:
#                 json.dump(values, outfile)
#             # Open file data with binary encoding
#             data_b = open(data_file, 'rb')
#             # Upload to bucket
#             s3 = boto3.resource(
#                 's3',
#                 aws_access_key_id = ACCESS_KEY_ID,
#                 aws_secret_access_key = ACCESS_SECRET_KEY,
#                 config = Config(signature_version = 's3v4')
#             )
#             s3.Bucket(BUCKET_NAME).put_object(Key = data_file, Body = data_b, ACL='public-read', ContentType='text/plain')
#             print(values)
#                  
#             time = TIME_CONST
#             print("Done grabbing sensor data and uploading to AWS Bucket")
#     else:
#         print("Waiting", time, "more", end=" ")
#         if (time > 1):
#             print("seconds until grabbing sensor data and uploading to AWS Bucket")
#         else:
#             print("second until grabbing sensor data and uploading to AWS Bucket")
#         time = time - 1
#         sleep(1)

try:
    while True:
        print("Still working!")
        time.sleep(1)
        
except KeyboardInterrupt:
    GPIO.cleanup()
GPIO.cleanup()

