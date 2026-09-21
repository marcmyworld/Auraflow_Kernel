#!/bin/bash
set -e

DIR="$(readlink -f .)"
MAIN="$(readlink -f "${DIR}/..")"

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

KBUILD_COMPILER_STRING="$($CLANG_DIR/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export KBUILD_COMPILER_STRING

KERNEL_DIR="$(pwd)"
ZIMAGE_DIR="$KERNEL_DIR/out/arch/arm64/boot"
STOCK_BOOT="/mnt/android-kitchen/autoporter/project/hyperos-stock/images/boot.img"
MAGISKBOOT="/mnt/android-kitchen/mio/bin/Linux/x86_64/magiskboot"

blue='\033[0;34m'
cyan='\033[0;36m'
green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

build_single_kernel() {
    local PROFILE="$1"
    local DEFCONFIG="$2"

    local BUILD_START=$(date +"%s")

    echo -e "$cyan=================================================$nocol"
    echo -e "$cyan       BUILDING AURAFLOW KERNEL ($PROFILE)$nocol"
    echo -e "$cyan       Unified SM8635 / cliffs (chenfeng & peridot)    $nocol"
    echo -e "$cyan=================================================$nocol"
    echo -e "Compiler:  $KBUILD_COMPILER_STRING"
    echo -e "Clang Dir: $CLANG_DIR"
    echo -e "Defconfig: $DEFCONFIG"

    # Build defconfig
    make $DEFCONFIG O=out CC=clang LLVM=1 LLVM_IAS=1

    # Compile kernel Image
    make -j$(nproc --all) O=out \
                          CC=clang \
                          ARCH=arm64 \
                          LLVM=1 \
                          LLVM_IAS=1 \
                          Image

    local BUILD_END=$(date +"%s")
    local DIFF=$(($BUILD_END - $BUILD_START))

    if [ ! -f "$ZIMAGE_DIR/Image" ]; then
        echo -e "$red[!] Build failed! $ZIMAGE_DIR/Image not found.$nocol"
        exit 1
    fi

    local TIME="$(date "+%Y%m%d-%H%M%S")"
    local ZIP_NAME="Auraflow-Kernel-${PROFILE}-${TIME}.zip"
    local BOOT_IMG_NAME="boot-auraflow-${PROFILE,,}.img"

    echo -e "$green[+] Kernel compilation completed in $(($DIFF / 60))m $(($DIFF % 60))s.$nocol"
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
    if [ -f "$STOCK_BOOT" ] && [ -x "$MAGISKBOOT" ]; then
        echo -e "$yellow[*] Creating standalone flashable $BOOT_IMG_NAME...$nocol"
        local REPACK_DIR="$(mktemp -d /tmp/auraflow_repack_XXXXXX)"
        cd "$REPACK_DIR"
        "$MAGISKBOOT" unpack -h "$STOCK_BOOT" > /dev/null 2>&1
        cp -fp "$ZIMAGE_DIR/Image" kernel
        "$MAGISKBOOT" repack "$STOCK_BOOT" "$KERNEL_DIR/$BOOT_IMG_NAME" > /dev/null 2>&1
        cd "$KERNEL_DIR"
        rm -rf "$REPACK_DIR"

        if [ -f "$KERNEL_DIR/$BOOT_IMG_NAME" ]; then
            echo -e "$green[+] Standalone boot image created: $BOOT_IMG_NAME$nocol"
        fi
    fi

    echo -e "$green=================================================$nocol"
    echo -e "$green   Build complete ($PROFILE)! Output files:$nocol"
    echo -e "   - AnyKernel3 Zip:  $KERNEL_DIR/$ZIP_NAME"
    [ -f "$KERNEL_DIR/$BOOT_IMG_NAME" ] && echo -e "   - Standalone Boot: $KERNEL_DIR/$BOOT_IMG_NAME"
    echo -e "$green=================================================$nocol"
    echo ""
}

TARGET="${1,,}"

if [ "$TARGET" == "all" ]; then
    echo -e "$green[*] Building all three Auraflow Kernel profiles...$nocol"
    build_single_kernel "Balanced" "chenfeng_defconfig"
    build_single_kernel "Battery" "chenfeng_battery_defconfig"
    build_single_kernel "Performance" "chenfeng_performance_defconfig"
elif [ "$TARGET" == "battery" ]; then
    build_single_kernel "Battery" "chenfeng_battery_defconfig"
elif [ "$TARGET" == "performance" ]; then
    build_single_kernel "Performance" "chenfeng_performance_defconfig"
elif [ "$TARGET" == "balanced" ]; then
    build_single_kernel "Balanced" "chenfeng_defconfig"
else
    # Auto-detect from branch name
    BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "auraflow-balanced")"
    if [[ "$BRANCH" =~ "battery" ]]; then
        build_single_kernel "Battery" "chenfeng_battery_defconfig"
    elif [[ "$BRANCH" =~ "performance" ]]; then
        build_single_kernel "Performance" "chenfeng_performance_defconfig"
    else
        build_single_kernel "Balanced" "chenfeng_defconfig"
    fi
fi
