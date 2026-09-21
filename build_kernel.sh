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
    local PROFILE="$1"          # NEO or TURBO
    local ROOT_MODE="$2"        # Vanilla or SukiSU
    local DEFCONFIG="$3"        # defconfig filename
    local SUBFOLDER_NAME="${PROFILE}-${ROOT_MODE}"
    local TARGET_DIR="$ARTIFACTS_DIR/$SUBFOLDER_NAME"
    mkdir -p "$TARGET_DIR"

    local DATE="$(date "+%Y%m%d")"
    local ZIP_NAME=""
    local BOOT_IMG_NAME=""

    if [ "$ROOT_MODE" = "Root" ]; then
        ZIP_NAME="Auraflow-Kernel-${PROFILE}-Root-v35159-SUSFS-${DATE}.zip"
        BOOT_IMG_NAME="Auraflow-Boot-${PROFILE}-Root-v35159-SUSFS-${DATE}.img"
    else
        ZIP_NAME="Auraflow-Kernel-${PROFILE}-Vanilla-${DATE}.zip"
        BOOT_IMG_NAME="Auraflow-Boot-${PROFILE}-Vanilla-${DATE}.img"
    fi

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

    # For Root variants, provide the matching ReSukiSU Manager APKs
    if [ "$ROOT_MODE" = "Root" ] && [ -d "$MANAGERS_DIR" ]; then
        echo -e "$yellow[*] Providing ReSukiSU Manager APKs in $SUBFOLDER_NAME and artifacts/ReSukiSU-Managers...$nocol"
        mkdir -p "$ARTIFACTS_DIR/ReSukiSU-Managers"
        [ -f "$MANAGERS_DIR/ReSukiSU_v4.2.0_Manager.apk" ] && cp -fp "$MANAGERS_DIR/ReSukiSU_v4.2.0_Manager.apk" "$TARGET_DIR/" && cp -fp "$MANAGERS_DIR/ReSukiSU_v4.2.0_Manager.apk" "$ARTIFACTS_DIR/ReSukiSU-Managers/"
        [ -f "$MANAGERS_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk" ] && cp -fp "$MANAGERS_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk" "$TARGET_DIR/" && cp -fp "$MANAGERS_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk" "$ARTIFACTS_DIR/ReSukiSU-Managers/"
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
    echo -e "$greenGenerated Fastboot Standalone Boot Images (fastboot flash boot_ab <file>):$nocol"
    for img in "${GENERATED_IMGS[@]}"; do
        local sz=$(ls -lh "$ARTIFACTS_DIR/$img" 2>/dev/null | awk '{print $5}')
        local sha=$(sha256sum "$ARTIFACTS_DIR/$img" 2>/dev/null | awk '{print $1}')
        echo -e "  * $img ($sz)"
        echo -e "    SHA256: $sha"
    done
    echo ""
    if [ -d "$ARTIFACTS_DIR/ReSukiSU-Managers" ]; then
        echo -e "$greenReSukiSU Manager APKs (v4.2.0 / 35159, UAPI v4):$nocol"
        for apk in "$ARTIFACTS_DIR/ReSukiSU-Managers"/*.apk; do
            if [ -f "$apk" ]; then
                local apk_name="$(basename "$apk")"
                local sz=$(ls -lh "$apk" 2>/dev/null | awk '{print $5}')
                local sha=$(sha256sum "$apk" 2>/dev/null | awk '{print $1}')
                echo -e "  * $apk_name ($sz)"
                echo -e "    SHA256: $sha"
            fi
        done
        echo ""
    fi
    echo -e "All artifacts are organized into subfolders in: $ARTIFACTS_DIR"
    echo -e "$cyan=======================================================================$nocol"
}

show_help() {
    echo "Auraflow Kernel Build Script"
    echo "Usage: $0 [MODE_OPTION] [PROFILE]"
    echo ""
    echo "Profiles:"
    echo "  neo                        Intelligent daily driver (balanced & power efficient, default)"
    echo "  turbo                      High performance profile (low latency & high sustained clocks)"
    echo "  all                        Both NEO and TURBO profiles"
    echo ""
    echo "Modes:"
    echo "  --vanilla, -v, --nonroot   Build only Non-Root (Vanilla) variant (default)"
    echo "  --root, -r                 Build only ReSukiSU + SUSFS + NoMount variant"
    echo "  --all, -a                  Build both Non-Root and Root variants"
    echo ""
    echo "Examples:"
    echo "  $0                         Build Vanilla NEO kernel"
    echo "  $0 neo                     Build Vanilla NEO kernel"
    echo "  $0 turbo                   Build Vanilla TURBO kernel"
    echo "  $0 --root neo              Build Root NEO kernel"
    echo "  $0 --root turbo            Build Root TURBO kernel"
    echo "  $0 --all neo               Build both Vanilla and Root NEO kernels"
    echo "  $0 --all turbo             Build both Vanilla and Root TURBO kernels"
    echo "  $0 --all                   Build all 4 kernel variants (NEO & TURBO, Vanilla & Root)"
    echo "  $0 --root all              Build Root variants for both NEO and TURBO"
}

build_profile_nonroot() {
    local prof="$1"
    case "$prof" in
        neo)
            build_single_kernel "NEO" "Vanilla" "chenfeng_neo_defconfig"
            ;;
        turbo)
            build_single_kernel "TURBO" "Vanilla" "chenfeng_turbo_defconfig"
            ;;
    esac
}

build_profile_root() {
    local prof="$1"
    case "$prof" in
        neo)
            build_single_kernel "NEO" "Root" "chenfeng_neo_sukisu_defconfig"
            ;;
        turbo)
            build_single_kernel "TURBO" "Root" "chenfeng_turbo_sukisu_defconfig"
            ;;
    esac
}

MODE="vanilla"
PROFILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root|-r)
            MODE="root"
            shift
            ;;
        --vanilla|--vanila|-v|--nonroot)
            MODE="vanilla"
            shift
            ;;
        --all|-a)
            MODE="all"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        neo|turbo|all)
            PROFILE="${1,,}"
            shift
            ;;
        # Backwards compatibility aliases
        balanced|battery)
            PROFILE="neo"
            shift
            ;;
        performance)
            PROFILE="turbo"
            shift
            ;;
        *)
            echo -e "$red[!] Unknown argument: $1$nocol"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$PROFILE" ]; then
    if [ "$MODE" = "all" ]; then
        PROFILE="all"
    else
        PROFILE="neo"
    fi
fi

if [ "$PROFILE" = "all" ]; then
    TARGET_PROFILES=("neo" "turbo")
else
    TARGET_PROFILES=("$PROFILE")
fi

echo -e "$green[*] Build Mode: $MODE | Profile(s): ${TARGET_PROFILES[*]}$nocol"

for p in "${TARGET_PROFILES[@]}"; do
    if [ "$MODE" = "vanilla" ] || [ "$MODE" = "all" ]; then
        build_profile_nonroot "$p"
    fi
    if [ "$MODE" = "root" ] || [ "$MODE" = "all" ]; then
        build_profile_root "$p"
    fi
done

print_summary
