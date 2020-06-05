# Cedric Kong
# CSE 475
# 4/30/2020
# Convert the Keras model file to TensorFlow Lite model
import tensorflow as tf

saved_model_path = r"C:\Users\Cedric\PycharmProjects\CSE475-ML\Trained_Model"
converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_path)
tflite_model = converter.convert()
open("converted_model.tflite", "wb").write(tflite_model)