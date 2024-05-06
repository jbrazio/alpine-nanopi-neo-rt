#!/bin/bash

set -e
set -o pipefail

source config.sh
source functions.sh

rm -rf ${BUILD_PATH}/*
rm -rf ${OUTPUT_PATH}/*
