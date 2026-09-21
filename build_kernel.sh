#!/bin/bash
set -e

DIR="$(readlink -f .)"
MAIN="$(readlink -f "${DIR}/..")"

# Profile detection: argument first, then git branch, fallback to balanced
ARG_PROFILE="$1"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "auraflow-balanced")"

if [ -n "$ARG_PROFILE" ]; then
    KERNEL_PROFILE="$ARG_PROFILE"
elif [[ "$BRANCH" =~ "battery" ]]; then
    KERNEL_PROFILE="Battery"
elif [[ "$BRANCH" =~ "performance" ]]; then
    KERNEL_PROFILE="Performance"
else
    KERNEL_PROFILE="Balanced"
fi

KERNEL_DEFCONFIG="chenfeng_defconfig"

# Locate Clang
if [ -d "$MAIN/resources/clang" ]; then
    CLANG_DIR="$MAIN/resources/clang"
elif [ -d "$MAIN/clang" ]; then
    CLANG_DIR="$MAIN/clang"
else
    echo "Clang compiler not found! Looked in $MAIN/resources/clang and $MAIN/clang"
    exit 1
fi

export PATH="$CLANG_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$CLANG_DIR/lib:$LD_LIBRARY_PATH"
export ARCH=arm64
export SUBARCH=arm64

export KBUILD_COMPILER_STRING="$($CLANG_DIR/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

KERNEL_DIR="$(pwd)"
ZIMAGE_DIR="$KERNEL_DIR/out/arch/arm64/boot"
BUILD_START=$(date +"%s")

blue='\033[0;34m'
cyan='\033[0;36m'
green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo -e "$cyan=================================================$nocol"
echo -e "$cyan       BUILDING AURAFLOW KERNEL ($KERNEL_PROFILE)$nocol"
echo -e "$cyan       Unified SM8635 / cliffs (chenfeng & peridot)    $nocol"
echo -e "$cyan=================================================$nocol"
echo -e "Compiler:  $KBUILD_COMPILER_STRING"
echo -e "Clang Dir: $CLANG_DIR"
echo -e "Defconfig: $KERNEL_DEFCONFIG"

# Build defconfig
make $KERNEL_DEFCONFIG O=out CC=clang LLVM=1 LLVM_IAS=1

# Compile kernel Image
make -j$(nproc --all) O=out \
                      CC=clang \
                      ARCH=arm64 \
                      LLVM=1 \
                      LLVM_IAS=1 \
                      Image

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

if [ ! -f "$ZIMAGE_DIR/Image" ]; then
    echo -e "$red[!] Build failed! $ZIMAGE_DIR/Image not found.$nocol"
    exit 1
fi

TIME="$(date "+%Y%m%d-%H%M%S")"
ZIP_NAME="Auraflow-Kernel-${KERNEL_PROFILE}-${TIME}.zip"
BOOT_IMG_NAME="boot-auraflow-${KERNEL_PROFILE,,}.img"

echo -e "$green[+] Kernel compilation completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
echo -e "$yellow[*] Packaging flashable AnyKernel3 zip...$nocol"

rm -rf tmp
mkdir -p tmp
cp -rp ./anykernel/* tmp/
cp -fp "$ZIMAGE_DIR/Image" tmp/Image
cd tmp
7za a -mx9 tmp.zip * > /dev/null
cd ..
cp -fp tmp/tmp.zip "$ZIP_NAME"
rm -rf tmp

echo -e "$green[+] AnyKernel3 zip created: $ZIP_NAME$nocol"

# Standalone boot.img creation
STOCK_BOOT="/mnt/android-kitchen/autoporter/project/hyperos-stock/images/boot.img"
MAGISKBOOT="/mnt/android-kitchen/mio/bin/Linux/x86_64/magiskboot"

if [ -f "$STOCK_BOOT" ] && [ -x "$MAGISKBOOT" ]; then
    echo -e "$yellow[*] Creating standalone flashable $BOOT_IMG_NAME...$nocol"
    REPACK_DIR="$(mktemp -d /tmp/auraflow_repack_XXXXXX)"
    cd "$REPACK_DIR"
    "$MAGISKBOOT" unpack -h "$STOCK_BOOT" > /dev/null 2>&1
    cp -fp "$ZIMAGE_DIR/Image" kernel
    "$MAGISKBOOT" repack "$STOCK_BOOT" "$KERNEL_DIR/$BOOT_IMG_NAME" > /dev/null 2>&1
    cd "$KERNEL_DIR"
    rm -rf "$REPACK_DIR"

    if [ -f "$KERNEL_DIR/$BOOT_IMG_NAME" ]; then
        echo -e "$green[+] Standalone boot image created: $BOOT_IMG_NAME$nocol"
        echo -e "    Header details:"
        (
            TMP_CHECK="$(mktemp -d /tmp/auraflow_check_XXXXXX)"
            cd "$TMP_CHECK"
            "$MAGISKBOOT" unpack -h "$KERNEL_DIR/$BOOT_IMG_NAME" 2>&1 | sed 's/^/    /'
            cd "$KERNEL_DIR"
            rm -rf "$TMP_CHECK"
        )
    fi
else
    echo -e "$yellow[!] Stock boot.img or magiskboot not found, skipping standalone boot.img creation.$nocol"
fi

echo -e "$green=================================================$nocol"
echo -e "$green   Build complete! Output files:$nocol"
echo -e "   - AnyKernel3 Zip:  $KERNEL_DIR/$ZIP_NAME"
[ -f "$KERNEL_DIR/$BOOT_IMG_NAME" ] && echo -e "   - Standalone Boot: $KERNEL_DIR/$BOOT_IMG_NAME"
echo -e "$green=================================================$nocol"
