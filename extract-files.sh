#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=gts210ltexx
VENDOR=samsung

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        vendor/lib/libsec-ril.so)
            "${PATCHELF}" --replace-needed "libcutils.so" "libcutils-v29.so" --replace-needed "libprotobuf-cpp-fast.so" "libprotobuf-cpp-fl26.so" "${2}"
            ;;
    case "${1}" in
        vendor/lib/mediadrm/libwvdrmengine.so)
            "${PATCHELF}" --replace-needed libprotobuf-cpp-lite.so libprotobuf-cpp-lite-v29.so "${2}"
            ;;
    case "${1}" in
        vendor/lib/libwvhidl.so)
            "${PATCHELF}" --replace-needed libprotobuf-cpp-lite.so libprotobuf-cpp-lite-v29.so "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"
echo "extract-files.sh ${PATCHELF}"
extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

#
#BLOB_ROOT="$ANDROID_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary
#if needed to change from original Samsung muppetized library names
#sed -i 's|libprotobuf-cpp-fulN.so|libprotobuf-cpp-full.so|g' $BLOB_ROOT/vendor/lib/libwvhidl.so
#sed -i 's|libprotobuf-cpp-fulN.so|libprotobuf-cpp-full.so|g' $BLOB_ROOT/vendor/lib/libsec-ril.so
(perl -pi -e "s/\/system\/bin\/gpsd/\/vendor\/bin\/gpsd/g" $BLOB_ROOT/system/lib/libsec-ril.so)

"${MY_DIR}/setup-makefiles.sh"
