#!/bin/bash

set -e
source config.sh
source functions.sh

TARGET=ramdisk
BASEPATH=$( dirname "$(readlink -f "${0}")" )

[ -d "${WORK_PATH}" ]   || mkdir "${WORK_PATH}"
[ -d "${BUILD_PATH}" ]  || mkdir "${BUILD_PATH}"
[ -d "${OUTPUT_PATH}" ] || mkdir "${OUTPUT_PATH}"

einfo "Downloading Alpine image package.."
[ -d "${BUILD_PATH}/${TARGET}" ] || mkdir "${BUILD_PATH}/${TARGET}"
[ -f "${BUILD_PATH}/${IMAGE_BINARY}" ] || wget "${IMAGE_SOURCE}" -O "${BUILD_PATH}/${IMAGE_BINARY}"

einfo "Extracting the tarball.."
if [ ! -d "${BUILD_PATH}/${TARGET}/unpack" ]; then
  mkdir -p "${BUILD_PATH}/${TARGET}/unpack"
  tar zxf "${BUILD_PATH}/${IMAGE_BINARY}" -C "${BUILD_PATH}/${TARGET}/unpack"
fi;

einfo "Extracting existing apkvol.."
if [ ! -d "${BUILD_PATH}/${TARGET}/apkvol" ]; then
  mkdir -p "${BUILD_PATH}/${TARGET}/apkvol"
  tar zxf "${BUILD_PATH}/${TARGET}/unpack/alpine.apkovl.tar.gz" -C "${BUILD_PATH}/${TARGET}/apkvol"
fi;

if [ -d "${BUILD_PATH}/../include/apkvol" ]; then
  einfo "Updating apkvol.."
  cp -af "${BUILD_PATH}/../include/apkvol/." "${BUILD_PATH}/${TARGET}/apkvol"
fi;


einfo "Extracting existing ramdisk.."
if [ ! -d "${BUILD_PATH}/${TARGET}/ramdisk" ]; then
  mkdir -p "${BUILD_PATH}/${TARGET}/ramdisk"
  zcat "${BUILD_PATH}/${TARGET}/unpack/boot/initramfs-vanilla" | cpio -i -D "${BUILD_PATH}/${TARGET}/ramdisk"
fi;

if [ -d "${BUILD_PATH}/../include/ramdisk" ]; then
  einfo "Updating ramdisk.."
  cp -af "${BUILD_PATH}/../include/ramdisk/." "${BUILD_PATH}/${TARGET}/ramdisk"
fi;

if [ -n "${DO_RAMDISK_SHELL}" ]; then
  cd "${BUILD_PATH}/${TARGET}/ramdisk" && bash || true
  cd "${BASEPATH}"
fi;

einfo "Installing modules into new ramdisk.."
if [ -d "${OUTPUT_PATH}/lib/modules" ]; then
  rm -rf "${BUILD_PATH}/${TARGET}/ramdisk/lib/modules"
  cp -af "${OUTPUT_PATH}/lib/modules" "${BUILD_PATH}/${TARGET}/ramdisk/lib"
fi;

einfo "Building u-boot compatible ramdisk.."
cd "${BUILD_PATH}/${TARGET}/ramdisk/"
find . | cpio -H newc -o | gzip -9 > "../initramfs-${TARGET_FAMILY}"
cd "${BASEPATH}"

mkimage -n "initramfs-${TARGET_FAMILY}" -A ${TARGET_ARCH} -O linux -T ramdisk -C none -d \
  "${BUILD_PATH}/${TARGET}/initramfs-${TARGET_FAMILY}" "${OUTPUT_PATH}/initramfs-${TARGET_FAMILY}"

einfo "Building apkvol tarball.."
cd "${BUILD_PATH}/${TARGET}/apkvol/"
tar --owner=root --group=root -czf "${BASEPATH}/${OUTPUT_PATH}/alpine.apkovl.tar.gz" *
cd "${BASEPATH}"

einfo "Caching apk files.."
cp -af "${BUILD_PATH}/${TARGET}/unpack/apks"                 "${OUTPUT_PATH}"
#cp -af "${BUILD_PATH}/${TARGET}/unpack/alpine.apkovl.tar.gz" "${OUTPUT_PATH}"

einfo "Cleanup.."
[ -n "${DEBUG}" ] && tree "${BUILD_PATH}/${TARGET}/ramdisk"
exit 0
