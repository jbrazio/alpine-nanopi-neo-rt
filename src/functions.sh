#!/bin/bash

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
export NCURSES_NO_UTF8_ACS=1

BUILD_PATH=/build
OUTPUT_PATH=/out
WORK_PATH=$(mktemp -d /tmp/work.XXXXXX)

# Basic
CORES=4
START_LBA=2048
SECTOR_SIZE=512

# Target config
TARGET_ARCH=arm
TARGET_FAMILY=sunxi
TARGET_BOARD=nanopi_neo
TARGET_DT=sun8i-h3-nanopi-neo.dtb

# Sources
UBOOT_SOURCE=https://github.com/u-boot/u-boot.git
KERNEL_SOURCE=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KERNEL_RT_SOURCE=https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/5.4/older/patch-${KERNEL_RT_VERSION}.patch.gz
KERNEL_XENOMAI_SOURCE=https://gitlab.denx.de/Xenomai/ipipe-arm.git
XENOMAI_TOOLKIT_SOURCE=https://gitlab.denx.de/Xenomai/xenomai.git


die() {
	printf '\033[1;31mERROR:\033[0m %s\n' "$@" >&2  # bold red
	exit 1
}

einfo() {
	printf '\n\033[1;36m> %s\033[0m\n' "$@" >&2  # bold cyan
}

ewarn() {
	printf '\033[1;33m> %s\033[0m\n' "$@" >&2  # bold yellow
}
