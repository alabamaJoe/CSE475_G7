# Cedric Kong
# CSE 475
# 4/30/2020
# The model creation for the CSE 475 Plant.ai capstone project. It uses an existing Mobilenet V2 module.
# The model is retrained to detect images of basil and jade. The images are resized, batched,
# and augmented before used for training. The training is evaluated at the end of each epoch and
# is terminated early if the accuracy plateaus. The learning rate also is adjusted each epoch.
#
# Link to tutorial:
# https://github.com/tensorflow/hub/blob/master/examples/colab/tf2_image_retraining.ipynb

import itertools
import os
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub
from tensorflow.python.client import device_lib
import pathlib
from PIL import Image
from time import time
from tensorflow.python.keras.callbacks import TensorBoard

# System validation that TF is connected to the GPU.
# Uncomment to recheck connection.
# system = tf.config.list_physical_devices('GPU')
# print("Num of GPUs:", len(system))
# print(device_lib.list_local_devices())

# Learning rate scheduler. Hyperbolically decrease learning rate.
def scheduler(epoch, lr):
    learningRate = lr * tf.math.exp(-0.1)
    print("Learning rate:", learningRate)
    return learningRate


# Visual check that the batches are as expected
def show_batch(image_batch, label_batch):
    plt.figure(figsize=(10, 10))
    for n in range(BATCH_SIZE):
        ax = plt.subplot(8, 8, n + 1)
        plt.imshow(image_batch[n])
        plt.title(CLASS_NAMES[label_batch[n] == 1][0].title())
        plt.axis('off')
    plt.show()


# Tensorboard for live results
tensorboard = TensorBoard(log_dir="logs\{}".format(time()))

# Early Stopping for when the validation accuracy plateaus or begins to degrade.
# Patience is how many epochs to observe a trend before terminating the training.
earlyStop = tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=3)

# Save best model
modelCheckpoint = tf.keras.callbacks.ModelCheckpoint(filepath=r"C:\Users\Cedric\PycharmProjects\CSE475-ML\Trained_Model",
                                                     monitor='val_accuracy',
                                                     mode='max',
                                                     save_best_only=True)

# Instantiate a callback object
my_callback = [tensorboard, earlyStop, modelCheckpoint, tf.keras.callbacks.LearningRateScheduler(scheduler)
               #,myCallback()
               ]

# Selecting and loading pre-trained, Mobilenet V2 module in TF2 SavedModel format
module_selection = ("mobilenet_v2_100_224", 224)
handle_base, pixels = module_selection
MODULE_HANDLE = "https://tfhub.dev/google/imagenet/mobilenet_v2_100_224/feature_vector/4".format(handle_base)
IMAGE_SIZE = (pixels, pixels)
print("Using {} with input size {}".format(MODULE_HANDLE, IMAGE_SIZE))
BATCH_SIZE = 32

# Loading plant dataset. Includes photos of jade plants and basil.
data_dir = r"C:\Users\Cedric\PycharmProjects\CSE475-ML\Plant_Training_Set"
data_dir = pathlib.Path(data_dir)
# print(data_dir)

# Number of photos
image_count = len(list(data_dir.glob('*/*.jpg')))
# print(image_count)

# Define classes
CLASS_NAMES = np.array([item.name for item in data_dir.glob('*') if item.name != "LICENSE.txt"])
# print(CLASS_NAMES)

# Reformat dataset to match expected image input size
# Define conditions for the training
datagen_kwargs = dict(rescale=1. / 255, validation_split=.30)
dataflow_kwargs = dict(target_size=IMAGE_SIZE, batch_size=BATCH_SIZE,
                       interpolation="bilinear")

valid_datagen = tf.keras.preprocessing.image.ImageDataGenerator(**datagen_kwargs)
valid_generator = valid_datagen.flow_from_directory(directory=data_dir,
                                                    subset="validation",
                                                    shuffle=True,
                                                    **dataflow_kwargs)

# Data augmentation to the images before use in the training
do_data_augmentation = True
if do_data_augmentation:
    train_datagen = tf.keras.preprocessing.image.ImageDataGenerator(
        rotation_range=0,
        horizontal_flip=True,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        **datagen_kwargs)
else:
    train_datagen = valid_datagen

# Defining training dataset
train_generator = train_datagen.flow_from_directory(directory=data_dir,
                                                    subset="training",
                                                    shuffle=True,
                                                    **dataflow_kwargs)

# View a batch
image_batch, label_batch = next(train_generator)
show_batch(image_batch, label_batch)

# Defining the model
# For speed, we start out with a non-trainable feature_extractor_layer, but you can also
# enable fine-tuning for greater accuracy
do_fine_tuning = True
print("Building model with", MODULE_HANDLE)
model = tf.keras.Sequential([
    # Explicitly define the input shape so the model can be properly
    # loaded by the TFLiteConverter
    tf.keras.layers.InputLayer(input_shape=IMAGE_SIZE + (3,)),
    hub.KerasLayer(MODULE_HANDLE, trainable=do_fine_tuning),
    tf.keras.layers.Dropout(rate=0.2),
    tf.keras.layers.Dense(train_generator.num_classes,
                          kernel_regularizer=tf.keras.regularizers.l2(0.0001))
])
model.build((None,) + IMAGE_SIZE + (3,))
model.summary()

# Training the model
model.compile(
    optimizer=tf.keras.optimizers.SGD(lr=0.00001, momentum=0.9),
    loss=tf.keras.losses.CategoricalCrossentropy(from_logits=True, label_smoothing=0.1),
    metrics=['accuracy'])

steps_per_epoch = train_generator.samples // train_generator.batch_size  # floor division
validation_steps = valid_generator.samples // valid_generator.batch_size
hist = model.fit(
    train_generator,
    epochs=25, steps_per_epoch=steps_per_epoch,
    validation_data=valid_generator,
    validation_steps=validation_steps,
    callbacks=my_callback).history


