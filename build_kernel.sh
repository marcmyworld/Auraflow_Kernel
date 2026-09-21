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
ARTIFACTS_DIR="$KERNEL_DIR/artifacts"
MANAGERS_DIR="$KERNEL_DIR/tools/sukisu_managers"

# Detect GKI LTS sublevel automatically from top-level Makefile
GKI_MAJOR=$(grep -E '^\s*VERSION\s*=' "$KERNEL_DIR/Makefile" | head -n 1 | awk '{print $3}')
GKI_PATCH=$(grep -E '^\s*PATCHLEVEL\s*=' "$KERNEL_DIR/Makefile" | head -n 1 | awk '{print $3}')
GKI_SUBLEVEL=$(grep -E '^\s*SUBLEVEL\s*=' "$KERNEL_DIR/Makefile" | head -n 1 | awk '{print $3}')
GKI_RELEASE="${GKI_MAJOR}.${GKI_PATCH}.${GKI_SUBLEVEL}"

# Read centralized Auraflow release version
if [ -f "$KERNEL_DIR/AURAFLOW_VERSION" ]; then
    AURAFLOW_VER="$(cat "$KERNEL_DIR/AURAFLOW_VERSION" | tr -d '[:space:]')"
else
    AURAFLOW_VER="1.0"
fi
AURAFLOW_VER="${AURAFLOW_VER#v}"

mkdir -p "$ARTIFACTS_DIR"

blue='\033[0;34m'
cyan='\033[0;36m'
green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

declare -a GENERATED_ZIPS=()

bump_version() {
    local NEW_VER="$1"
    NEW_VER="${NEW_VER#v}"
    if [ -z "$NEW_VER" ]; then
        echo -e "$red[!] Error: Please specify a version number (e.g. 1.1 or 2.0)$nocol"
        exit 1
    fi
    echo "$NEW_VER" > "$KERNEL_DIR/AURAFLOW_VERSION"
    echo -e "$green[+] Updated AURAFLOW_VERSION to: v${NEW_VER}$nocol"

    # Synchronize defconfigs to match
    sed -i -E "s/CONFIG_LOCALVERSION=\"-Auraflow-NEO-v[0-9.]+\"/CONFIG_LOCALVERSION=\"-Auraflow-NEO-v${NEW_VER}\"/" "$KERNEL_DIR"/arch/arm64/configs/chenfeng_neo*_defconfig "$KERNEL_DIR"/arch/arm64/configs/chenfeng_defconfig "$KERNEL_DIR"/arch/arm64/configs/chenfeng_sukisu_defconfig 2>/dev/null || true
    sed -i -E "s/CONFIG_LOCALVERSION=\"-Auraflow-TURBO-v[0-9.]+\"/CONFIG_LOCALVERSION=\"-Auraflow-TURBO-v${NEW_VER}\"/" "$KERNEL_DIR"/arch/arm64/configs/chenfeng_turbo*_defconfig 2>/dev/null || true

    echo -e "$green[+] Synchronized defconfigs with new release version v${NEW_VER}.$nocol"
    echo -e "$cyanTarget release names for GKI ${GKI_RELEASE}:$nocol"
    echo -e "  NEO:   ${GKI_RELEASE}-Auraflow-NEO-v${NEW_VER}+"
    echo -e "  TURBO: ${GKI_RELEASE}-Auraflow-TURBO-v${NEW_VER}+"
    exit 0
}

check_lts() {
    echo -e "$cyan=================================================$nocol"
    echo -e "$cyan        AURAFLOW GKI & LTS VERSION STATUS        $nocol"
    echo -e "$cyan=================================================$nocol"
    echo -e "Current Local GKI Base:        Linux ${GKI_RELEASE}"
    echo -e "Current Auraflow Version:      v${AURAFLOW_VER}"
    echo -e "Target Kernel Release (NEO):   ${GKI_RELEASE}-Auraflow-NEO-v${AURAFLOW_VER}+"
    echo -e "Target Kernel Release (TURBO): ${GKI_RELEASE}-Auraflow-TURBO-v${AURAFLOW_VER}+"
    echo ""
    echo -e "$yellow[*] Querying kernel.org for latest Linux 6.1.y LTS release...$nocol"
    local LATEST_61=$(curl -s --connect-timeout 4 https://www.kernel.org/releases.json 2>/dev/null | grep -o '"version": "6\.1\.[0-9]*"' | head -n 1 | awk -F'"' '{print $4}')
    if [ -n "$LATEST_61" ]; then
        echo -e "Latest Upstream 6.1.y LTS:     Linux $LATEST_61"
        if [ "$GKI_RELEASE" = "$LATEST_61" ]; then
            echo -e "$green[+] Your local kernel GKI base is completely up to date with upstream LTS!$nocol"
        else
            echo -e "$yellow[i] Notice: Upstream 6.1.y has progressed to $LATEST_61 (Local is $GKI_RELEASE).$nocol"
            echo -e "    When you rebase/merge the latest GKI sublevel into the tree, the build system"
            echo -e "    will automatically detect and compile with that GKI release without any manual edits."
        fi
    else
        echo -e "$yellow[!] Could not connect to kernel.org (offline or connection timed out).$nocol"
    fi
    echo -e "$cyan=================================================$nocol"
    exit 0
}

build_single_kernel() {
    local PROFILE="$1"          # NEO or TURBO
    local ROOT_MODE="$2"        # Vanilla or Root
    local DEFCONFIG="$3"        # defconfig filename
    local SUBFOLDER_NAME="${PROFILE}-${ROOT_MODE}"
    local TARGET_DIR="$ARTIFACTS_DIR/$SUBFOLDER_NAME"
    mkdir -p "$TARGET_DIR"

    local DATE="$(date "+%Y%m%d")"
    local ZIP_NAME=""

    if [ "$ROOT_MODE" = "Root" ]; then
        ZIP_NAME="Auraflow-Kernel-${PROFILE}-Root-v35159-SUSFS-${DATE}.zip"
    else
        ZIP_NAME="Auraflow-Kernel-${PROFILE}-Vanilla-${DATE}.zip"
    fi

    local EXPECTED_UTS="${GKI_RELEASE}-Auraflow-${PROFILE}-v${AURAFLOW_VER}+"
    local BUILD_START=$(date +"%s")

    echo -e "$cyan=================================================$nocol"
    echo -e "$cyan       BUILDING AURAFLOW KERNEL                 $nocol"
    echo -e "$cyan       Profile:          $PROFILE               $nocol"
    echo -e "$cyan       Root Mode:        $ROOT_MODE             $nocol"
    echo -e "$cyan       GKI Base:         $GKI_RELEASE (Auto)    $nocol"
    echo -e "$cyan       Auraflow Ver:     v$AURAFLOW_VER (Manual)$nocol"
    echo -e "$cyan       Kernel Release:   $EXPECTED_UTS          $nocol"
    echo -e "$cyan       Output Path:      artifacts/$SUBFOLDER_NAME $nocol"
    echo -e "$cyan       Unified SM8635 / cliffs (chenfeng & peridot) $nocol"
    echo -e "$cyan=================================================$nocol"
    echo -e "Compiler:  $KBUILD_COMPILER_STRING"
    echo -e "Clang Dir: $CLANG_DIR"
    echo -e "Defconfig: $DEFCONFIG"

    # Clean old kernel image if any
    rm -f "$ZIMAGE_DIR/Image"

    # Configure defconfig
    make $DEFCONFIG O=out CC=clang LLVM=1 LLVM_IAS=1

    # Dynamically inject CONFIG_LOCALVERSION using centralized versioning
    "$KERNEL_DIR/scripts/config" --file "$KERNEL_DIR/out/.config" --set-str LOCALVERSION "-Auraflow-${PROFILE}-v${AURAFLOW_VER}"

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

    # For Root variants, provide ONLY the spoofed ReSukiSU Manager in the variant folder
    if [ "$ROOT_MODE" = "Root" ] && [ -d "$MANAGERS_DIR" ]; then
        echo -e "$yellow[*] Providing Spoofed ReSukiSU Manager in $SUBFOLDER_NAME...$nocol"
        [ -f "$MANAGERS_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk" ] && cp -fp "$MANAGERS_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk" "$TARGET_DIR/"
        # Ensure any old standard manager is removed from the variant folder
        rm -f "$TARGET_DIR/ReSukiSU_v4.2.0_Manager.apk"
    fi

    # Ensure the Manager folder in artifacts has BOTH original and spoofed manager
    if [ -d "$MANAGERS_DIR" ]; then
        local MGR_DIR="$ARTIFACTS_DIR/Manager"
        mkdir -p "$MGR_DIR"
        [ -f "$MANAGERS_DIR/ReSukiSU_v4.2.0_Manager.apk" ] && cp -fp "$MANAGERS_DIR/ReSukiSU_v4.2.0_Manager.apk" "$MGR_DIR/"
        [ -f "$MANAGERS_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk" ] && cp -fp "$MANAGERS_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk" "$MGR_DIR/"
        # Backward compatibility aliases
        ln -sfn "Manager" "$ARTIFACTS_DIR/Managers" 2>/dev/null || true
        ln -sfn "Manager" "$ARTIFACTS_DIR/ReSukiSU-Managers" 2>/dev/null || true
    fi

    echo -e "$green=================================================$nocol"
    echo -e "$green   Variant complete: $PROFILE ($ROOT_MODE)$nocol"
    echo -e "   - Folder:          artifacts/$SUBFOLDER_NAME"
    echo -e "   - AnyKernel3 Zip:  artifacts/$SUBFOLDER_NAME/$ZIP_NAME"
    echo -e "   - Kernel Release:  $EXPECTED_UTS"
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
    if [ -d "$ARTIFACTS_DIR/Manager" ]; then
        echo -e "$greenReSukiSU Managers in artifacts/Manager/ (Original & Spoofed):$nocol"
        for apk in "$ARTIFACTS_DIR/Manager"/*.apk; do
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
    echo "Version & LTS Utilities:"
    echo "  --bump-version, -b <ver>   Bump Auraflow release version (e.g. 1.1) across files & defconfigs"
    echo "  --check-lts, -c            Check current GKI base against upstream Linux 6.1.y LTS"
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
    echo "  $0 --bump-version 1.1      Bump Auraflow version to 1.1"
    echo "  $0 --check-lts             Check upstream 6.1.y LTS release status"
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
        --bump-version|-b)
            shift
            bump_version "$1"
            ;;
        --check-lts|--check-gki|-c)
            check_lts
            ;;
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
echo -e "$cyan[*] GKI Base: $GKI_RELEASE | Auraflow Version: v$AURAFLOW_VER$nocol"

for p in "${TARGET_PROFILES[@]}"; do
    if [ "$MODE" = "vanilla" ] || [ "$MODE" = "all" ]; then
        build_profile_nonroot "$p"
    fi
    if [ "$MODE" = "root" ] || [ "$MODE" = "all" ]; then
        build_profile_root "$p"
    fi
done

print_summary
