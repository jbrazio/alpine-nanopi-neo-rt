#!/bin/bash

set -e
set -o pipefail

source config.sh
source functions.sh

[ -d "${WORK_PATH}" ]   || mkdir "${WORK_PATH}"
[ -d "${BUILD_PATH}" ]  || mkdir "${BUILD_PATH}"
[ -d "${OUTPUT_PATH}" ] || mkdir "${OUTPUT_PATH}"

einfo "Downloading u-boot ${BRANCH} source from git.."
[ -d "${BUILD_PATH}/u-boot" ] || git clone --depth=1 --branch "${UBOOT_VERSION}" "${UBOOT_SOURCE}" "${BUILD_PATH}/u-boot"

einfo "Creating u-boot config file.."
make -C "${BUILD_PATH}/u-boot" "${TARGET_BOARD}_defconfig"

echo "CONFIG_NET_RANDOM_ETHADDR=y" >> "${BUILD_PATH}/u-boot/.config"

einfo "Checking for DO_UBOOT_MENUCONFIG flag.."
[ -n "${DO_UBOOT_MENUCONFIG}" ] && make -C "${BUILD_PATH}/u-boot" menuconfig 2>/dev/null || true

einfo "Building u-boot.."
make -C "${BUILD_PATH}/u-boot" -j$(awk "BEGIN {print 1.5 * ${CORES}}") all

einfo "Creating u-boot macro file.."
cat <<EOF > "${OUTPUT_PATH}/boot.cmd"
setenv machid 1029
setenv bootargs earlyprintk modules=loop,squashfs,sd-mod,usb-storage modloop=/boot/modloop-${TARGET_FAMILY} console=\${console}
load mmc 0:1 0x41000000 boot/vmlinuz-${TARGET_FAMILY}
load mmc 0:1 0x43000000 boot/dtbs/${TARGET_DT}
load mmc 0:1 0x45000000 boot/initramfs-${TARGET_FAMILY}
bootz 0x41000000 0x45000000 0x43000000
EOF

einfo "Collecting artifacts.."
cat "${OUTPUT_PATH}/boot.cmd"
cp -af "${BUILD_PATH}/u-boot/u-boot-${TARGET_FAMILY}-with-spl.bin" "${OUTPUT_PATH}"

einfo "Cleanup uboot.."
exit 0
