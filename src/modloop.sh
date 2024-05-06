#!/bin/bash

set -e
set -o pipefail

source config.sh
source functions.sh

[ -d "${WORK_PATH}" ]   || mkdir "${WORK_PATH}"
[ -d "${BUILD_PATH}" ]  || mkdir "${BUILD_PATH}"
[ -d "${OUTPUT_PATH}" ] || mkdir "${OUTPUT_PATH}"

[ -f "${OUTPUT_PATH}/modloop-${TARGET_FAMILY}" ] && rm "${OUTPUT_PATH}/modloop-${TARGET_FAMILY}"

einfo "Installing modules into modloop.."
mkdir -p "${WORK_PATH}/modloop"
cp -af "${OUTPUT_PATH}/lib/modules" "${WORK_PATH}/modloop"

einfo "Building modloop squashfs filesystem.."
mksquashfs "${WORK_PATH}/modloop" "${OUTPUT_PATH}/modloop-${TARGET_FAMILY}" -b 1048576 -comp xz -Xdict-size 100% -root-owned

einfo "Cleanup modloop.."
[ -n "${DEBUG}" ] && tree "${WORK_PATH}/modloop"
rm -rf "${WORK_PATH}/*"
exit 0
