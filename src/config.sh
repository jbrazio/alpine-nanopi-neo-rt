#!/bin/bash

# Basic
SDCARD_SIZE=256

# Realtime patch
#DO_BUILD_REALTIME_KERNEL=y
#DO_BUILD_XENOMAI_KERNEL=y

# Versions
UBOOT_VERSION=v2024.04
KERNEL_VERSION=v5.4.84
KERNEL_RT_VERSION=${KERNEL_VERSION//v}-rt47
#KERNEL_XENOMAI_VERSION=4.14.85

# Xenomai toolkit
#XENOMAI_VER=master

# Alpine
IMAGE_BINARY=alpine-uboot-3.19.1-armv7.tar.gz
IMAGE_SOURCE=https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/armv7/alpine-uboot-3.19.1-armv7.tar.gz
