#!/bin/bash

# Basic
CORES=4
SDCARD_SIZE=128M
DO_BUILD_REALTIME_KERNEL=y
#DO_BUILD_XENOMAI_KERNEL=y

BUILD_PATH=build
OUTPUT_PATH=output
WORK_PATH=$(mktemp -d /tmp/work.XXXXXX)

# Target config
TARGET_ARCH=arm
TARGET_FAMILY=sunxi
TARGET_BOARD=nanopi_neo
TARGET_DT=sun8i-h3-nanopi-neo.dtb

# U-Boot
UBOOT_VERSION=v2019.04-rc2
UBOOT_SOURCE=https://github.com/u-boot/u-boot.git

# Kernel
KERNEL_VERSION=v4.20.10
KERNEL_SOURCE=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KERNEL_DOWLOAD_TARBALL=y

# RT Kernel
KERNEL_VER_RT=v4.18.16
KERNEL_SRC_RT=https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/4.18/older/patch-4.18.16-rt8.patch.gz

# Xenomai Kernel
#KERNEL_VER_XENOMAI=4.14.85
#KERNEL_SRC_XENOMAI=https://gitlab.denx.de/Xenomai/ipipe-arm.git

# Xenomai toolkit
#XENOMAI_VER=master
#XENOMAI_SRC=https://gitlab.denx.de/Xenomai/xenomai.git

# Initramfs
IMAGE_ARCH=armhf
IMAGE_BINARY=alpine-uboot-3.9.0-armhf.tar.gz
IMAGE_SOURCE=http://dl-cdn.alpinelinux.org/alpine/v3.9/releases/${IMAGE_ARCH}/${IMAGE_BINARY}
