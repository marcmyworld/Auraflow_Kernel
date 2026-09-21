# Auraflow Kernel

Custom, high-performance, and security-focused Linux kernel built for **Xiaomi SM8650 / SM8635** unified platforms (**Xiaomi 14 Civi / Civi 4 Pro** `chenfeng` and **POCO F6 / Redmi Turbo 3** `peridot`).

---

## Highlights & Features

- **Upstream LTS Base**: Rebased and updated to **Linux 6.1.174 LTS** (`android14-6.1.174_r00`).
- **Kernel Version Release String**:
  - 🌟 **NEO**: `6.1.174-Auraflow-NEO-v1.0+` (reported as `6.1*-Auraflow-NEO-v1.0+` in `uname -r` / Android Settings)
  - 🚀 **TURBO**: `6.1.174-Auraflow-TURBO-v1.0+` (reported as `6.1*-Auraflow-TURBO-v1.0+` in `uname -r` / Android Settings)
- **Unified cliffs / SM8635 Architecture**: Single unified codebase booting cleanly across both **Xiaomi 14 Civi / Civi 4 Pro** (`chenfeng`) and **POCO F6 / Redmi Turbo 3** (`peridot`).
- **Compiler Toolchain**: Built with **ZyC Clang 16.0.6** utilizing the full LLVM integrated assembler (`LLVM_IAS=1`) and ThinLTO.
- **Root, Security & Stealth Stack**:
  - **Vanilla (Non-Root)**: Stock-compliant, unrooted kernel variant ideal for banking applications, enterprise compliance, and Play Integrity.
  - **ReSukiSU v4.2.0 (Build 35159, UAPI v4)**: Modern, multi-manager in-kernel root management solution ([ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)).
  - **SUSFS v2.3.0 Integration**: Native filesystem and mount isolation with inline kernel hooks (`CONFIG_KSU_SUSFS=y`) providing stealth root hiding.
  - **KPM (Kernel Patch Module v0.11.0)**: Native in-kernel module loader and runtime control (`CONFIG_KPM=y`), fully integrated with ReSukiSU.
  - **NoMount Subsystem**: Baked-in [NoMount](https://github.com/maxsteeel/nomount) path redirection subsystem (`CONFIG_NOMOUNT=y`) enabling stealth root modules and file injection without mounting filesystem overlays.
  - **Full Feature Suite Active**: Classic SU compatibility, Kernel umount, ADB Root, SELinux Hide, and SU Logging all fully registered and functional (not greyed out).
- **Modern Profile Philosophy**:
  - 🌟 **NEO** (Default): Intelligent daily driver delivering optimal power efficiency and buttery smoothness. Configured with power-efficient workqueues (`CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y`), balanced energy curve governor (`CONFIG_KP_DEFAULT_MODE=2`), responsive touch boost, and extended battery life.
  - 🚀 **TURBO**: High, plausibly feasible sustained performance focusing on low-latency scheduling, sustained CPU clocks, and rapid thread wakeups for heavy gaming and intensive multitasking (`CONFIG_KP_DEFAULT_MODE=3`, low-latency workqueues).
- **ReSukiSU Manager (Default Theme Experience)**:
  - ✨ **Blur** enabled by default (`isEnableBlur = true`, `isEnableBlurExp = true`)
  - 🌊 **Floating Bottom Bar** enabled by default (`BottomBarStyle.FLOATING`)
  - 💎 **Liquid Glass** shader effect active on navigation bars
  - 🔄 **Predictive Back Gesture** enabled by default (`Scale` animation)
  - Pre-signed with Auraflow release keystore matching driver verification.

---

## Available Variants & Profiles

Auraflow Kernel is organized into **2 performance profiles** across **2 root modes** (2×2 = 4 release targets):

| Profile | Mode | Kernel Release (`uname -r`) | Key Configurations | Output Folder |
|---|---|---|---|---|
| **NEO** | Vanilla (Non-Root) | `6.1.174-Auraflow-NEO-v1.0+` | Power-efficient workqueues, balanced energy curve, unrooted | `artifacts/NEO-Vanilla/` |
| **NEO** | Root (ReSukiSU + SUSFS + KPM + NoMount) | `6.1.174-Auraflow-NEO-v1.0+` | Power-efficient workqueues, ReSukiSU v35159, SUSFS v2.3.0, KPM, NoMount | `artifacts/NEO-Root/` |
| **TURBO** | Vanilla (Non-Root) | `6.1.174-Auraflow-TURBO-v1.0+` | Low-latency scheduling, sustained high clocks, unrooted | `artifacts/TURBO-Vanilla/` |
| **TURBO** | Root (ReSukiSU + SUSFS + KPM + NoMount) | `6.1.174-Auraflow-TURBO-v1.0+` | Low-latency scheduling, ReSukiSU v35159, SUSFS v2.3.0, KPM, NoMount | `artifacts/TURBO-Root/` |

---

## Artifacts Structure

All compiled release packages and boot images are organized into dedicated subfolders inside `artifacts/`:

```text
artifacts/
├── NEO-Vanilla/
│   ├── Auraflow-Kernel-NEO-Vanilla-<YYYYMMDD>.zip
│   └── Auraflow-Boot-NEO-Vanilla-<YYYYMMDD>.img
│
├── NEO-Root/
│   ├── Auraflow-Kernel-NEO-Root-v35159-SUSFS-<YYYYMMDD>.zip
│   ├── Auraflow-Boot-NEO-Root-v35159-SUSFS-<YYYYMMDD>.img
│   ├── ReSukiSU_v4.2.0_Manager.apk
│   └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
│
├── TURBO-Vanilla/
│   ├── Auraflow-Kernel-TURBO-Vanilla-<YYYYMMDD>.zip
│   └── Auraflow-Boot-TURBO-Vanilla-<YYYYMMDD>.img
│
├── TURBO-Root/
│   ├── Auraflow-Kernel-TURBO-Root-v35159-SUSFS-<YYYYMMDD>.zip
│   ├── Auraflow-Boot-TURBO-Root-v35159-SUSFS-<YYYYMMDD>.img
│   ├── ReSukiSU_v4.2.0_Manager.apk
│   └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
│
└── ReSukiSU-Managers/
    ├── ReSukiSU_v4.2.0_Manager.apk
    └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
```

---

## Installation Guide

### Method 1: Custom Recovery (TWRP / OrangeFox) — Recommended
1. Reboot the device into custom recovery.
2. Copy the desired `Auraflow-Kernel-<Profile>-*.zip` to device storage.
3. Flash the `.zip` archive via the recovery install menu.
4. Reboot to system.

### Method 2: Fastboot Standalone Boot Image
1. Reboot your device into Fastboot mode:
   ```bash
   adb reboot bootloader
   ```
2. Flash the standalone boot image directly across both slots:
   ```bash
   fastboot flash boot_ab <boot_image_name>.img
   ```
   *Example:*
   ```bash
   fastboot flash boot_ab Auraflow-Boot-NEO-Root-v35159-SUSFS-20260922.img
   ```
3. Reboot the phone:
   ```bash
   fastboot reboot
   ```

### ReSukiSU Manager Setup (Root Variants)
- For Root variants, install `ReSukiSU_v4.2.0_Manager.apk` or `ReSukiSU_v4.2.0_Spoofed_Manager.apk` from the variant folder or `artifacts/ReSukiSU-Managers/`.
- The Manager is pre-configured with Blur, Floating Bottom Bar, Liquid Glass, and Predictive Back animations active by default.
- Signed with the persistent Auraflow release keystore (`8aa0f658cba545308d65c0aaee8b85f98ad54230d1c9f6065a8e156358d48c09`), recognized by `apk_sign_keys[]` in the kernel driver.
- KPM module control, Superuser grants, NoMount metamodule support, and SUSFS mount hiding work straight out of the box.

---

## Building from Source

The entire build and packaging pipeline is managed via `./build_kernel.sh`:

### Build Vanilla (Non-Root) Variants
```bash
# Build NEO Vanilla (default)
./build_kernel.sh neo
# or explicitly
./build_kernel.sh --vanilla neo

# Build TURBO Vanilla
./build_kernel.sh --vanilla turbo
```

### Build Root (ReSukiSU + SUSFS + KPM + NoMount) Variants
```bash
# Build NEO Root variant
./build_kernel.sh --root neo

# Build TURBO Root variant
./build_kernel.sh --root turbo
```

### Build Both Variants for a Profile
```bash
# Build both Vanilla and Root for NEO
./build_kernel.sh --all neo

# Build both Vanilla and Root for TURBO
./build_kernel.sh --all turbo
```

### Build All 4 Variants
```bash
./build_kernel.sh --all
```

---

## Hardware & OS Compatibility

- **Target Devices**:
  - **Xiaomi 14 Civi / Civi 4 Pro** (`chenfeng` / `chenfengin`)
  - **POCO F6 / Redmi Turbo 3** (`peridot`)
- **SoC**: Qualcomm Snapdragon 8s Gen 3 (`SM8635` / `cliffs`)
- **Supported Android OS**: **Android 14 and all above versions (Android 14+)**, fully supporting:
  - Android 14
  - Android 15 / Android 15 QPR
  - Future Android versions
  - Xiaomi HyperOS 1.0 & HyperOS 2.0
  - AOSP, LineageOS, Evolution X, PixelOS, and all modern custom ROMs
