#!/bin/bash

set -e
set -o pipefail

source config.sh
source functions.sh

trap 'handle_exit' EXIT

handle_exit() {
  einfo "Cleaning sdcard.."
  umount "${WORK_PATH}" || true
  kpartx -dvs /dev/${LOOP} || true
  losetup -d /dev/${LOOP} || true
}

IMAGE=${OUTPUT_PATH}/sdcard-alpine-${TARGET_FAMILY}-${TARGET_BOARD}-${SDCARD_SIZE}M.img

[ -d "${BUILD_PATH}" ] || mkdir "${BUILD_PATH}"

einfo "Creating ${SDCARD_SIZE}Mb base image file.."
dd if=/dev/zero of="${IMAGE}" bs=${SDCARD_SIZE}M count=1

einfo "Burning the SPL loader and u-boot into the image file.."
dd conv=notrunc if="${OUTPUT_PATH}/u-boot-${TARGET_FAMILY}-with-spl.bin" of="${IMAGE}" bs=1024 seek=8

einfo "Writting the partition table.."

SIZE_SECTORS=$(( 128 * 1024 * 1024 / 512 ))
END_LBA=$(( SIZE_SECTORS - START_LBA ))

sfdisk "${IMAGE}" <<EOF
unit: sectors
p1 : start=${START_LBA}, size=${END_LBA}, Id=0c
EOF

einfo "Map image partitions.."
LOOP=$( kpartx -avs "${IMAGE}" | grep -Po 'loop[[:digit:]]+' | head -1 )

if ! [ -b "/dev/${LOOP}" ]; then
  kpartx -dvs "${IMAGE}"
  die "Unable to get loop device (${LOOP})"
fi

einfo "Creating FAT32 filesystem.."
mkdosfs -F 32 -n "NanoPI Neo" -I /dev/mapper/${LOOP}p1

einfo "Mounting /dev/${LOOP}.."
mount -ouser,umask=0000 /dev/mapper/${LOOP}p1 "${WORK_PATH}" || exit 1

einfo "Copying files to the FAT32 partition.."
mkdir -p "${WORK_PATH}/boot/dtbs"

cp -f "${OUTPUT_PATH}/vmlinuz-${TARGET_FAMILY}"   "${WORK_PATH}/boot"
cp -f "${OUTPUT_PATH}/modloop-${TARGET_FAMILY}"   "${WORK_PATH}/boot"
cp -f "${OUTPUT_PATH}/initramfs-${TARGET_FAMILY}" "${WORK_PATH}/boot"
cp -f "${OUTPUT_PATH}/${TARGET_DT}"               "${WORK_PATH}/boot/dtbs"
cp -f "${OUTPUT_PATH}/alpine.apkovl.tar.gz"       "${WORK_PATH}/alpine-neo.apkovl.tar.gz"
cp -Rf "${OUTPUT_PATH}/apks"                      "${WORK_PATH}"

mkimage -C none -A ${TARGET_ARCH} -T script -d "${OUTPUT_PATH}/boot.cmd" "${WORK_PATH}/boot/boot.scr"

if [ -d "${BUILD_PATH}/../include/sdcard" ]; then
  einfo "Copying additional files to the FAT32 partition.."
  cp -Rf "${BUILD_PATH}/../include/sdcard/." "${WORK_PATH}"
fi;

exit 0
