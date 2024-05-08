#!/bin/bash

set -e
set -o pipefail

source config.sh
source functions.sh

rm -rf ${OUTPUT_PATH}/*

# make -C "${BUILD_PATH}/u-boot" distclean
make -C "${BUILD_PATH}/linux-${KERNEL_VERSION//v}" distclean