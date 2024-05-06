#!/bin/bash

set -e
set -o pipefail

source config.sh
source functions.sh

rm -rf ${OUTPUT_PATH}/*
