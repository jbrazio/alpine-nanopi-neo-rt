#!/bin/bash

set -e
source config.sh
source functions.sh

IMAGE=${OUTPUT_PATH}/sdcard-alpine-${TARGET_FAMILY}-${TARGET_BOARD}-${SDCARD_SIZE}.img

[ -d "${BUILD_PATH}" ] || mkdir "${BUILD_PATH}"

einfo "Creating ${SDCARD_SIZE} base image file.."
dd if=/dev/zero of="${IMAGE}" bs=${SDCARD_SIZE} count=1

einfo "Burning the SPL loader and u-boot into the image file.."
dd conv=notrunc if="${OUTPUT_PATH}/u-boot-${TARGET_FAMILY}-with-spl.bin" of="${IMAGE}" bs=1024 seek=8

einfo "Writting the partition table.."
sfdisk "${IMAGE}" <<EOF
unit: sectors
p1 : start=2048, Id=0c
EOF

einfo "Map image partitions.."
LOOP=$( sudo kpartx -avs "${IMAGE}" | grep -Po 'loop[[:digit:]]+' | head -1 )

einfo "Creating FAT32 filesystem.."
sudo mkdosfs -F 32 -I /dev/mapper/${LOOP}p1

einfo "Mounting /dev/mapper/${LOOP}p1.."
sudo mount -ouser,umask=0000 /dev/mapper/${LOOP}p1 "${WORK_PATH}" || exit 1

einfo "Copying files to the FAT32 partition.."
mkdir -p "${WORK_PATH}/boot/dtbs"

cp -f "${OUTPUT_PATH}/vmlinuz-${TARGET_FAMILY}"   "${WORK_PATH}/boot"
cp -f "${OUTPUT_PATH}/modloop-${TARGET_FAMILY}"   "${WORK_PATH}/boot"
cp -f "${OUTPUT_PATH}/initramfs-${TARGET_FAMILY}" "${WORK_PATH}/boot"
cp -f "${OUTPUT_PATH}/${TARGET_DT}"               "${WORK_PATH}/boot/dtbs"
cp -f "${OUTPUT_PATH}/alpine.apkovl.tar.gz"       "${WORK_PATH}"

cp -Rf "${OUTPUT_PATH}/apks"                      "${WORK_PATH}"

mkimage -C none -A ${TARGET_ARCH} -T script -d "${OUTPUT_PATH}/boot.cmd" "${WORK_PATH}/boot/boot.scr"

if [ -d "${BUILD_PATH}/../include/sdcard" ]; then
  einfo "Copying additional files to the FAT32 partition.."
  cp -Rf "${BUILD_PATH}/../include/sdcard/." "${WORK_PATH}"
fi;


einfo "Cleanup.."
[ -n "${DEBUG}" ] && tree ${WORK_PATH}
sleep 1
sync

sudo umount "${WORK_PATH}"
rm -rf "${WORK_PATH}"

sudo kpartx -dvs "${IMAGE}"
sudo losetup -d /dev/${LOOP} 2>/dev/null || true

exit 0
