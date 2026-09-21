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
ARTIFACTS_DIR="$KERNEL_DIR/artifacts"
MANAGERS_DIR="$KERNEL_DIR/tools/sukisu_managers"

mkdir -p "$ARTIFACTS_DIR"

blue='\033[0;34m'
cyan='\033[0;36m'
green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

declare -a GENERATED_ZIPS=()
declare -a GENERATED_IMGS=()

build_single_kernel() {
    local PROFILE="$1"          # Balanced, Battery, Performance
    local ROOT_MODE="$2"        # Non-Root, SukiSU-SUSFS
    local DEFCONFIG="$3"        # defconfig filename
    local ZIP_PREFIX="$4"       # Auraflow-Kernel-Balanced, etc.
    local BOOT_NAME="$5"        # boot-auraflow-balanced.img, etc.
    local SUBFOLDER_NAME="$6"   # Balanced-NonRoot, Balanced-SukiSU-SUSFS, etc.

    local TARGET_DIR="$ARTIFACTS_DIR/$SUBFOLDER_NAME"
    mkdir -p "$TARGET_DIR"

    local BUILD_START=$(date +"%s")

    echo -e "$cyan=================================================$nocol"
    echo -e "$cyan       BUILDING AURAFLOW KERNEL                 $nocol"
    echo -e "$cyan       Profile:     $PROFILE                    $nocol"
    echo -e "$cyan       Root Mode:   $ROOT_MODE                  $nocol"
    echo -e "$cyan       Output Path: artifacts/$SUBFOLDER_NAME   $nocol"
    echo -e "$cyan       Unified SM8635 / cliffs (chenfeng & peridot) $nocol"
    echo -e "$cyan=================================================$nocol"
    echo -e "Compiler:  $KBUILD_COMPILER_STRING"
    echo -e "Clang Dir: $CLANG_DIR"
    echo -e "Defconfig: $DEFCONFIG"

    # Clean old kernel image if any
    rm -f "$ZIMAGE_DIR/Image"

    # Configure defconfig
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
    local ZIP_NAME="${ZIP_PREFIX}-${TIME}.zip"
    local BOOT_IMG_NAME="${BOOT_NAME}"

    echo -e "$green[+] Kernel compilation completed in $(($DIFF / 60))m $(($DIFF % 60))s.$nocol"
    echo -e "$yellow[*] Packaging flashable AnyKernel3 zip: $ZIP_NAME...$nocol"

    rm -rf tmp
    mkdir -p tmp
    cp -rp ./anykernel/* tmp/
    cp -fp "$ZIMAGE_DIR/Image" tmp/Image
    sed -i "s|VARIANT_PLACEHOLDER|${PROFILE} (${ROOT_MODE})|g" tmp/anykernel.sh
    cd tmp
    7za a -mx9 tmp.zip * > /dev/null
    cd ..
    cp -fp tmp/tmp.zip "$TARGET_DIR/$ZIP_NAME"
    rm -rf tmp

    GENERATED_ZIPS+=("$SUBFOLDER_NAME/$ZIP_NAME")
    echo -e "$green[+] AnyKernel3 zip created: artifacts/$SUBFOLDER_NAME/$ZIP_NAME$nocol"

    # Standalone boot.img creation
    if [ -f "$STOCK_BOOT" ] && [ -x "$MAGISKBOOT" ]; then
        echo -e "$yellow[*] Creating standalone flashable $BOOT_IMG_NAME...$nocol"
        local REPACK_DIR="$(mktemp -d /tmp/auraflow_repack_XXXXXX)"
        cd "$REPACK_DIR"
        "$MAGISKBOOT" unpack -h "$STOCK_BOOT" > /dev/null 2>&1
        cp -fp "$ZIMAGE_DIR/Image" kernel
        "$MAGISKBOOT" repack "$STOCK_BOOT" "$TARGET_DIR/$BOOT_IMG_NAME" > /dev/null 2>&1
        cd "$KERNEL_DIR"
        rm -rf "$REPACK_DIR"

        if [ -f "$TARGET_DIR/$BOOT_IMG_NAME" ]; then
            GENERATED_IMGS+=("$SUBFOLDER_NAME/$BOOT_IMG_NAME")
            echo -e "$green[+] Standalone boot image created: artifacts/$SUBFOLDER_NAME/$BOOT_IMG_NAME$nocol"
        fi
    fi

    # For SukiSU variants, provide the matching SukiSU Ultra Manager APKs
    if [[ "$SUBFOLDER_NAME" =~ "SukiSU" ]] && [ -d "$MANAGERS_DIR" ]; then
        echo -e "$yellow[*] Copying SukiSU Ultra Manager APKs to $SUBFOLDER_NAME...$nocol"
        [ -f "$MANAGERS_DIR/SukiSU_v4.2.0_Manager.apk" ] && cp -fp "$MANAGERS_DIR/SukiSU_v4.2.0_Manager.apk" "$TARGET_DIR/"
        [ -f "$MANAGERS_DIR/SukiSU_v4.2.0_Spoofed_Manager.apk" ] && cp -fp "$MANAGERS_DIR/SukiSU_v4.2.0_Spoofed_Manager.apk" "$TARGET_DIR/"
    fi

    echo -e "$green=================================================$nocol"
    echo -e "$green   Variant complete: $PROFILE ($ROOT_MODE)$nocol"
    echo -e "   - Folder:          artifacts/$SUBFOLDER_NAME"
    echo -e "   - AnyKernel3 Zip:  artifacts/$SUBFOLDER_NAME/$ZIP_NAME"
    [ -f "$TARGET_DIR/$BOOT_IMG_NAME" ] && echo -e "   - Standalone Boot: artifacts/$SUBFOLDER_NAME/$BOOT_IMG_NAME"
    echo -e "$green=================================================$nocol"
    echo ""
}

print_summary() {
    echo ""
    echo -e "$cyan=======================================================================$nocol"
    echo -e "$cyan                    AURAFLOW BUILD ARTIFACTS SUMMARY                $nocol"
    echo -e "$cyan=======================================================================$nocol"
    echo -e "$greenGenerated AnyKernel3 Flashable Zips (Flash via TWRP / OrangeFox):$nocol"
    for z in "${GENERATED_ZIPS[@]}"; do
        local sz=$(ls -lh "$ARTIFACTS_DIR/$z" 2>/dev/null | awk '{print $5}')
        local sha=$(sha256sum "$ARTIFACTS_DIR/$z" 2>/dev/null | awk '{print $1}')
        echo -e "  * $z ($sz)"
        echo -e "    SHA256: $sha"
    done
    echo ""
    echo -e "$greenGenerated Fastboot Standalone Boot Images (fastboot flash boot <file>):$nocol"
    for img in "${GENERATED_IMGS[@]}"; do
        local sz=$(ls -lh "$ARTIFACTS_DIR/$img" 2>/dev/null | awk '{print $5}')
        local sha=$(sha256sum "$ARTIFACTS_DIR/$img" 2>/dev/null | awk '{print $1}')
        echo -e "  * $img ($sz)"
        echo -e "    SHA256: $sha"
    done
    echo ""
    echo -e "All artifacts are organized into subfolders in: $ARTIFACTS_DIR"
    echo -e "$cyan=======================================================================$nocol"
}

TARGET="${1,,}"

case "$TARGET" in
    all)
        echo -e "$green[*] Building all 6 Auraflow Kernel variants (3 Profiles x 2 Root Modes)...$nocol"
        # 1. Balanced Non-Root
        build_single_kernel "Balanced" "Non-Root" "chenfeng_defconfig" "Auraflow-Kernel-Balanced" "boot-auraflow-balanced.img" "Balanced-NonRoot"
        # 2. Balanced SukiSU-Ultra + SUSFS + KPM
        build_single_kernel "Balanced" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_sukisu_defconfig" "Auraflow-Kernel-Balanced-SukiSU-SUSFS" "boot-auraflow-balanced-sukisu.img" "Balanced-SukiSU-SUSFS"
        # 3. Battery Non-Root
        build_single_kernel "Battery" "Non-Root" "chenfeng_battery_defconfig" "Auraflow-Kernel-Battery" "boot-auraflow-battery.img" "Battery-NonRoot"
        # 4. Battery SukiSU-Ultra + SUSFS + KPM
        build_single_kernel "Battery" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_battery_sukisu_defconfig" "Auraflow-Kernel-Battery-SukiSU-SUSFS" "boot-auraflow-battery-sukisu.img" "Battery-SukiSU-SUSFS"
        # 5. Performance Non-Root
        build_single_kernel "Performance" "Non-Root" "chenfeng_performance_defconfig" "Auraflow-Kernel-Performance" "boot-auraflow-performance.img" "Performance-NonRoot"
        # 6. Performance SukiSU-Ultra + SUSFS + KPM
        build_single_kernel "Performance" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_performance_sukisu_defconfig" "Auraflow-Kernel-Performance-SukiSU-SUSFS" "boot-auraflow-performance-sukisu.img" "Performance-SukiSU-SUSFS"
        print_summary
        ;;
    nonroot)
        echo -e "$green[*] Building all 3 Non-Root variants...$nocol"
        build_single_kernel "Balanced" "Non-Root" "chenfeng_defconfig" "Auraflow-Kernel-Balanced" "boot-auraflow-balanced.img" "Balanced-NonRoot"
        build_single_kernel "Battery" "Non-Root" "chenfeng_battery_defconfig" "Auraflow-Kernel-Battery" "boot-auraflow-battery.img" "Battery-NonRoot"
        build_single_kernel "Performance" "Non-Root" "chenfeng_performance_defconfig" "Auraflow-Kernel-Performance" "boot-auraflow-performance.img" "Performance-NonRoot"
        print_summary
        ;;
    sukisu)
        echo -e "$green[*] Building all 3 SukiSU-Ultra + SUSFS + KPM variants...$nocol"
        build_single_kernel "Balanced" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_sukisu_defconfig" "Auraflow-Kernel-Balanced-SukiSU-SUSFS" "boot-auraflow-balanced-sukisu.img" "Balanced-SukiSU-SUSFS"
        build_single_kernel "Battery" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_battery_sukisu_defconfig" "Auraflow-Kernel-Battery-SukiSU-SUSFS" "boot-auraflow-battery-sukisu.img" "Battery-SukiSU-SUSFS"
        build_single_kernel "Performance" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_performance_sukisu_defconfig" "Auraflow-Kernel-Performance-SukiSU-SUSFS" "boot-auraflow-performance-sukisu.img" "Performance-SukiSU-SUSFS"
        print_summary
        ;;
    balanced)
        build_single_kernel "Balanced" "Non-Root" "chenfeng_defconfig" "Auraflow-Kernel-Balanced" "boot-auraflow-balanced.img" "Balanced-NonRoot"
        print_summary
        ;;
    balanced-sukisu)
        build_single_kernel "Balanced" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_sukisu_defconfig" "Auraflow-Kernel-Balanced-SukiSU-SUSFS" "boot-auraflow-balanced-sukisu.img" "Balanced-SukiSU-SUSFS"
        print_summary
        ;;
    battery)
        build_single_kernel "Battery" "Non-Root" "chenfeng_battery_defconfig" "Auraflow-Kernel-Battery" "boot-auraflow-battery.img" "Battery-NonRoot"
        print_summary
        ;;
    battery-sukisu)
        build_single_kernel "Battery" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_battery_sukisu_defconfig" "Auraflow-Kernel-Battery-SukiSU-SUSFS" "boot-auraflow-battery-sukisu.img" "Battery-SukiSU-SUSFS"
        print_summary
        ;;
    performance)
        build_single_kernel "Performance" "Non-Root" "chenfeng_performance_defconfig" "Auraflow-Kernel-Performance" "boot-auraflow-performance.img" "Performance-NonRoot"
        print_summary
        ;;
    performance-sukisu)
        build_single_kernel "Performance" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_performance_sukisu_defconfig" "Auraflow-Kernel-Performance-SukiSU-SUSFS" "boot-auraflow-performance-sukisu.img" "Performance-SukiSU-SUSFS"
        print_summary
        ;;
    *)
        echo -e "$yellow[*] Building Balanced variants (Non-Root & SukiSU-Ultra)...$nocol"
        build_single_kernel "Balanced" "Non-Root" "chenfeng_defconfig" "Auraflow-Kernel-Balanced" "boot-auraflow-balanced.img" "Balanced-NonRoot"
        build_single_kernel "Balanced" "SukiSU-Ultra + SUSFS + KPM" "chenfeng_sukisu_defconfig" "Auraflow-Kernel-Balanced-SukiSU-SUSFS" "boot-auraflow-balanced-sukisu.img" "Balanced-SukiSU-SUSFS"
        print_summary
        ;;
esac
