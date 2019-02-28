#!/bin/bash

set -e
source config.sh
source functions.sh

BASEPATH=$( dirname "$(readlink -f "${0}")" )

[ -d "${WORK_PATH}" ]   || mkdir "${WORK_PATH}"
[ -d "${BUILD_PATH}" ]  || mkdir "${BUILD_PATH}"
[ -d "${OUTPUT_PATH}" ] || mkdir "${OUTPUT_PATH}"

if [ -n "${DO_BUILD_REALTIME_KERNEL}" ]; then
  KERNEL_VERSION=${KERNEL_VER_RT}
fi

[ -f "${OUTPUT_PATH}/headers-${KERNEL_VERSION}.tar.gz" ] && rm "${OUTPUT_PATH}/headers-${KERNEL_VERSION}.tar.gz"

einfo "Building kernel headers tarball.."
cd "${OUTPUT_PATH}"
tar --owner=root --group=root -czf "${BASEPATH}/${OUTPUT_PATH}/headers-${KERNEL_VERSION}.tar.gz" "usr/"
cd "${BASEPATH}"

einfo "Cleanup.."
exit 0
