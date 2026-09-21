#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$(cd "$DIR/.." && pwd)"
MANAGER_DIR="$KERNEL_DIR/tools/manager"
KEYSTORE_PATH="$KERNEL_DIR/tools/keystore/auraflow-key.jks"
OUTPUT_DIR="$KERNEL_DIR/tools/sukisu_managers"
ARTIFACTS_MANAGERS_DIR="$KERNEL_DIR/artifacts/ReSukiSU-Managers"

blue='\033[0;34m'
cyan='\033[0;36m'
green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo -e "$cyan=================================================$nocol"
echo -e "$cyan       BUILDING RESUKISU MANAGERS               $nocol"
echo -e "$cyan=================================================$nocol"

# Locate Java 21
if [ -z "$JAVA_HOME" ]; then
    JDK21_CANDIDATE=$(find /home/sharkey/.gradle/jdks /usr/lib/jvm -name "java" -path "*/bin/java" 2>/dev/null | grep -E "21|temurin-21" | head -n 1 || true)
    if [ -n "$JDK21_CANDIDATE" ]; then
        export JAVA_HOME="$(dirname "$(dirname "$JDK21_CANDIDATE")")"
    fi
fi

if [ -n "$JAVA_HOME" ]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi

echo -e "Java Version: $(java -version 2>&1 | head -n 1)"

# Locate Android SDK
if [ -d "$HOME/android-sdk" ]; then
    export ANDROID_HOME="$HOME/android-sdk"
elif [ -z "$ANDROID_HOME" ] && [ -d "/opt/android-sdk" ]; then
    export ANDROID_HOME="/opt/android-sdk"
fi
export ANDROID_SDK_ROOT="$ANDROID_HOME"
echo -e "Android SDK:  $ANDROID_HOME"

if [ -z "$ANDROID_HOME" ]; then
    echo -e "$red[!] ANDROID_HOME is not set. Please set ANDROID_HOME to your Android SDK directory.$nocol"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
mkdir -p "$ARTIFACTS_MANAGERS_DIR"

# Ensure keystore is present in manager directory
if [ -f "$KEYSTORE_PATH" ]; then
    cp -fp "$KEYSTORE_PATH" "$MANAGER_DIR/auraflow-key.jks"
fi

# Ensure gradle.properties has signing configuration
cat << 'EOF' > "$MANAGER_DIR/gradle.properties"
android.experimental.enableNewResourceShrinker.preciseShrinking=true
android.enableAppCompileTimeRClass=true
android.useAndroidX=true
org.gradle.jvmargs=-Xmx2048m
org.gradle.parallel=true
org.gradle.tooling.parallel=true
org.gradle.vfs.watch=true
android.r8.maxWorkers=4
android.native.buildOutput=verbose

KEYSTORE_FILE=auraflow-key.jks
KEYSTORE_PASSWORD=auraflowsukisu
KEY_ALIAS=auraflow-key
KEY_PASSWORD=auraflowsukisu
EOF

# -------------------------------------------------------------
# 1. Build Standard ReSukiSU Manager
# -------------------------------------------------------------
echo -e "$yellow[*] Building Standard ReSukiSU Manager APK...$nocol"
cd "$MANAGER_DIR"
./gradlew clean assembleRelease

STD_APK=$(find "$MANAGER_DIR/app/build/outputs/apk/release" -type f -name "*universal*.apk" | head -n 1)
if [ -z "$STD_APK" ]; then
    STD_APK=$(find "$MANAGER_DIR/app/build/outputs/apk/release" -type f -name "*.apk" | head -n 1)
fi

if [ -f "$STD_APK" ]; then
    cp -fp "$STD_APK" "$OUTPUT_DIR/ReSukiSU_v4.2.0_Manager.apk"
    cp -fp "$STD_APK" "$ARTIFACTS_MANAGERS_DIR/ReSukiSU_v4.2.0_Manager.apk"
    echo -e "$green[+] Standard Manager APK built successfully:$nocol"
    echo -e "    $OUTPUT_DIR/ReSukiSU_v4.2.0_Manager.apk"
else
    echo -e "$red[!] Standard Manager build failed! APK not found.$nocol"
    exit 1
fi

# -------------------------------------------------------------
# 2. Build Spoofed ReSukiSU Manager
# -------------------------------------------------------------
echo -e "$yellow[*] Building Spoofed ReSukiSU Manager APK...$nocol"
cd "$MANAGER_DIR"
./gradlew assembleRelease -PIS_SPOOFED_BUILD=true -PKSU_PACKAGE_NAME=com.aura.resukisu

SPOOFED_APK=$(find "$MANAGER_DIR/app/build/outputs/apk/release" -type f -name "*universal*.apk" | head -n 1)
if [ -z "$SPOOFED_APK" ]; then
    SPOOFED_APK=$(find "$MANAGER_DIR/app/build/outputs/apk/release" -type f -name "*.apk" | head -n 1)
fi

if [ -f "$SPOOFED_APK" ]; then
    cp -fp "$SPOOFED_APK" "$OUTPUT_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk"
    cp -fp "$SPOOFED_APK" "$ARTIFACTS_MANAGERS_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk"
    echo -e "$green[+] Spoofed Manager APK built successfully:$nocol"
    echo -e "    $OUTPUT_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk"
else
    echo -e "$red[!] Spoofed Manager build failed! APK not found.$nocol"
    exit 1
fi

echo -e "$green=================================================$nocol"
echo -e "$green       RESUKISU MANAGERS BUILD COMPLETE          $nocol"
echo -e "$green=================================================$nocol"
echo -e "Standard Manager: $OUTPUT_DIR/ReSukiSU_v4.2.0_Manager.apk"
echo -e "Spoofed Manager:  $OUTPUT_DIR/ReSukiSU_v4.2.0_Spoofed_Manager.apk"
