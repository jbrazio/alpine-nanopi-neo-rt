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
  PATCH_FILE=${KERNEL_SRC_RT#*-}
fi

TARGET=${BUILD_PATH}/linux-${KERNEL_VERSION//v}

if [ ! -d "${TARGET}" ]; then
  if [ -z "${KERNEL_DOWLOAD_TARBALL}" ]; then
    einfo "Downloading kernel ${KERNEL_VERSION} source from git.."
    git clone --depth=1 --branch "${KERNEL_VERSION}" "${KERNEL_SOURCE}" "${TARGET}"
  else
    if [ ! -f "${BUILD_PATH}/linux-${KERNEL_VERSION//v}.tar.gz" ]; then
      einfo "Downloading kernel ${KERNEL_VERSION} tarball.."
      wget "https://www.kernel.org/pub/linux/kernel/${KERNEL_VERSION%%.*}.x/linux-${KERNEL_VERSION//v}.tar.gz" \
        -O "${BUILD_PATH}/linux-${KERNEL_VERSION//v}.tar.gz"
    fi

    mkdir "${TARGET}"
    einfo "Extracting kernel ${KERNEL_VERSION} tarball.."
    tar xf "${BUILD_PATH}/linux-${KERNEL_VERSION//v}.tar.gz" -C "${BUILD_PATH}"
  fi

  if [ -d "patch/kernel/${KERNEL_VERSION}" ]; then
    for PATCH in patch/kernel/${KERNEL_VERSION}/*.patch; do
      einfo "Applying $(basename ${PATCH}) to kernel.."
      patch -d "${TARGET}" -p1 < ${PATCH}
    done
  fi

  if [ -n "${DO_BUILD_REALTIME_KERNEL}" ]; then
    einfo "Downloading kernel ${KERNEL_VERSION} real time patch.."
    [ -f "${TARGET}/../${PATCH_FILE}" ] || wget ${KERNEL_SRC_RT} -O "${BUILD_PATH}/${PATCH_FILE}"

    einfo "Patching kernel with ${PATCH_FILE}.."
    zcat "${BUILD_PATH}/${PATCH_FILE}" | patch -d "${TARGET}" -p1 -R -N --dry-run --silent 1>/dev/null 2>&1 ||
      zcat "${BUILD_PATH}/${PATCH_FILE}" | patch -d "${TARGET}" -p1
  fi
fi

einfo "Creating default kernel config file.."
make -C "${TARGET}" "${TARGET_FAMILY}_defconfig"

einfo "Enabling the required kernel features.."
echo "CONFIG_IPV6=m"         >> "${TARGET}/.config"
echo "CONFIG_SQUASHFS=y"     >> "${TARGET}/.config"
echo "CONFIG_SQUASHFS_XZ=y"  >> "${TARGET}/.config"
echo "CONFIG_SYN_COOKIES=y"  >> "${TARGET}/.config"
echo "CONFIG_BLK_DEV_LOOP=y" >> "${TARGET}/.config"

if [ -n "${DO_BUILD_REALTIME_KERNEL}" ]; then
  echo "CONFIG_PREEMPT_RT_FULL=y" >> "${TARGET}/.config"
fi

einfo "Calculating kernel dependencies.."
make -C "${TARGET}" olddefconfig 2>/dev/null || true

einfo "Checking for DO_KERNEL_MENUCONFIG flag.."
[ -n "${DO_KERNEL_MENUCONFIG}" ] && make -C "${TARGET}" menuconfig

einfo "Building the kernel.."
make -C "${TARGET}" -j$(awk "BEGIN {print 1.5 * ${CORES}}")

einfo "Installing the modules.."
INSTALL_MOD_PATH="${BASEPATH}/${OUTPUT_PATH}" make -C "${TARGET}" -j$(awk "BEGIN {print 1.5 * ${CORES}}") modules_install

einfo "Installing the headers.."
#INSTALL_HDR_PATH="${BASEPATH}/${OUTPUT_PATH}"
make -C "${TARGET}" -j$(awk "BEGIN {print 1.5 * ${CORES}}") headers_install

einfo "Collecting artifacts.."
cp -af "${TARGET}/arch/${TARGET_ARCH}/boot/zImage" "${OUTPUT_PATH}/vmlinuz-${TARGET_FAMILY}"
cp -af "${TARGET}/arch/${TARGET_ARCH}/boot/dts/${TARGET_DT}" "${OUTPUT_PATH}/${TARGET_DT}"

[ -d "${OUTPUT_PATH}/usr" ] || mkdir "${OUTPUT_PATH}/usr"
cp -af "${TARGET}/usr/include" "${OUTPUT_PATH}/usr"

einfo "Cleanup.."
exit 0
