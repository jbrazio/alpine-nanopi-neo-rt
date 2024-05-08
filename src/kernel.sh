#!/bin/bash

set -e
set -o pipefail

source config.sh
source functions.sh

BASEPATH=$( dirname "$(readlink -f "${0}")" )

[ -d "${WORK_PATH}" ]   || mkdir "${WORK_PATH}"
[ -d "${BUILD_PATH}" ]  || mkdir "${BUILD_PATH}"
[ -d "${OUTPUT_PATH}" ] || mkdir "${OUTPUT_PATH}"

if [ -n "${DO_BUILD_REALTIME_KERNEL}" ]; then
	PATCH_FILE=${KERNEL_RT_SOURCE#*-}
fi

TARGET=${BUILD_PATH}/linux-${KERNEL_VERSION//v}

if [ ! -d "${TARGET}" ]; then
	einfo "Downloading kernel ${KERNEL_VERSION} source from git.."
	git clone --depth=1 --branch "${KERNEL_VERSION}" "${KERNEL_SOURCE}" "${TARGET}"

	if [ -n "${DO_BUILD_REALTIME_KERNEL}" ]; then
		einfo "Downloading kernel ${KERNEL_RT_VERSION} real time patch.."
		[ -f "${TARGET}/../${PATCH_FILE}" ] || wget ${KERNEL_RT_SOURCE} -O "${BUILD_PATH}/${PATCH_FILE}"

		einfo "Patching kernel with ${PATCH_FILE}.."
		zcat "${BUILD_PATH}/${PATCH_FILE}" | patch -d "${TARGET}" -p1 -R -N --dry-run --silent 1>/dev/null 2>&1 || \
			zcat "${BUILD_PATH}/${PATCH_FILE}" | patch -d "${TARGET}" -p1
	fi

	einfo "Cleanup kernel source repository.."
	rm -rf "${TARGET}/.git"
fi

if [ ! -f "${TARGET}/.config" ]; then
	einfo "Creating default kernel config file.."
	make -C "${TARGET}" "${TARGET_FAMILY}_defconfig"

	if [ -n "${DO_BUILD_REALTIME_KERNEL}" ]; then
		einfo "Enabling RT kernel.."
		${TARGET}/scripts/config --file "${TARGET}/.config" -e EXPERT
		${TARGET}/scripts/config --file "${TARGET}/.config" -e CONFIG_PREEMPT_RT
	fi

	if [ -d "${BASEPATH}/include/kernel" ]; then
		for conf in "${BASEPATH}/include/kernel"/*.conf; do
			if [ -r "${conf}" ]; then
				einfo "Processing kernel modules from ${conf}"
				while IFS= read -r line; do
					if [[ "$line" =~ ^CONFIG_ ]]; then
						config_option=$(echo "$line" | cut -d'=' -f1)
						config_value=$(echo "$line" | cut -d'=' -f2)
						case "$config_value" in
							y)
								"${TARGET}/scripts/config" --file "${TARGET}/.config" --enable "${config_option}"
								;;
							m)
								"${TARGET}/scripts/config" --file "${TARGET}/.config" --module "${config_option}"
								;;
							n)
								"${TARGET}/scripts/config" --file "${TARGET}/.config" --disable "${config_option}"
								;;
							*)
								"${TARGET}/scripts/config" --file "${TARGET}/.config" --set-val "${config_option}" "${config_value}"
								;;
						esac
					fi
				done < "${conf}"
			fi
		done
	fi

	einfo "Calculating kernel dependencies.."
	make -C "${TARGET}" olddefconfig
fi

einfo "Building the kernel.."
make -C "${TARGET}" clean
make -C "${TARGET}" -j$(awk "BEGIN {print 1.5 * ${CORES}}")

einfo "Installing the modules.."
INSTALL_MOD_PATH="${OUTPUT_PATH}" make -C "${TARGET}" -j$(awk "BEGIN {print 1.5 * ${CORES}}") modules_install

einfo "Installing the headers.."
make -C "${TARGET}" -j$(awk "BEGIN {print 1.5 * ${CORES}}") headers_install

einfo "Collecting artifacts.."
cp -af "${TARGET}/arch/${TARGET_ARCH}/boot/zImage" "${OUTPUT_PATH}/vmlinuz-${TARGET_FAMILY}"
cp -af "${TARGET}/arch/${TARGET_ARCH}/boot/dts/${TARGET_DT}" "${OUTPUT_PATH}/${TARGET_DT}"

[ -d "${OUTPUT_PATH}/usr" ] || mkdir "${OUTPUT_PATH}/usr"
cp -af "${TARGET}/usr/include" "${OUTPUT_PATH}/usr"

exit 0
