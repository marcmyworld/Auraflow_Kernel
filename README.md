# Auraflow Kernel

Custom, high-performance, and security-focused Linux kernel built for **Xiaomi SM8650 / SM8635** unified platforms (`chenfeng` - Xiaomi 14 Civi / Civi 4 Pro, and `peridot` - POCO F6 / Redmi Turbo 3).

---

## Highlights & Features

- **Upstream LTS Base**: Rebased and updated to **Linux 6.1.174 LTS** (`android14-6.1.174_r00`).
- **Kernel Version Release String**:
  - 🌟 **NEO**: `6.1.174-Auraflow-NEO-v1.0+` (reported as `6.1*-Auraflow-NEO-v1.0+` in `uname -r` / Android Settings)
  - 🚀 **TURBO**: `6.1.174-Auraflow-TURBO-v1.0+` (reported as `6.1*-Auraflow-TURBO-v1.0+` in `uname -r` / Android Settings)
- **Unified cliffs / SM8635 Architecture**: Single unified codebase booting cleanly on both **Xiaomi 14 Civi / Civi 4 Pro** (`chenfeng`) and **POCO F6 / Redmi Turbo 3** (`peridot`).
- **Compiler Toolchain**: Built with **ZyC Clang 16.0.6** utilizing the full LLVM integrated assembler (`LLVM_IAS=1`) and ThinLTO.
- **Root & Security Configurations**:
  - **Vanilla (Non-Root)**: Stock-compliant, unrooted kernel variant ideal for banking applications, enterprise compliance, and Play Integrity.
  - **SukiSU-Ultra v4.2.0 (Build 40939)**: Next-generation in-kernel root management solution with UAPI v2.
  - **SUSFS v2.3.0 Integration**: Native filesystem and mount isolation with inline kernel hooks (`CONFIG_KSU_SUSFS=y`) providing stealth root hiding.
  - **KPM (Kernel Patch Module v0.11.0)**: Native in-kernel module loading and runtime control (`CONFIG_KPM=y`), fully integrated with the SukiSU-Ultra Manager UI.
- **Modern Profile Philosophy**:
  - 🌟 **NEO** (Default): Intelligent daily driver delivering optimal power efficiency and buttery smoothness. Configured with power-efficient workqueues (`CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y`), balanced energy curve governor (`CONFIG_KP_DEFAULT_MODE=2`), responsive touch boost, and extended battery life.
  - 🚀 **TURBO**: High, plausibly feasible performance focusing on low-latency scheduling, sustained high CPU clocks, and rapid thread wakeups for heavy gaming and intensive multitasking (`CONFIG_KP_DEFAULT_MODE=3`, low-latency workqueues).

---

## Available Variants & Profiles

Auraflow Kernel is organized into **2 performance profiles** across **2 root modes** (2×2 = 4 release targets):

| Profile | Mode | Kernel Release (`uname -r`) | Key Configurations | Output Folder |
|---|---|---|---|---|
| **NEO** | Vanilla (Non-Root) | `6.1.174-Auraflow-NEO-v1.0+` | Power-efficient workqueues, balanced energy curve, unrooted | `artifacts/NEO-Vanilla/` |
| **NEO** | SukiSU + SUSFS + KPM | `6.1.174-Auraflow-NEO-v1.0+` | Power-efficient workqueues, SukiSU-Ultra v40939, SUSFS v2.3.0, KPM | `artifacts/NEO-SukiSU/` |
| **TURBO** | Vanilla (Non-Root) | `6.1.174-Auraflow-TURBO-v1.0+` | Low-latency scheduling, sustained high clocks, unrooted | `artifacts/TURBO-Vanilla/` |
| **TURBO** | SukiSU + SUSFS + KPM | `6.1.174-Auraflow-TURBO-v1.0+` | Low-latency scheduling, SukiSU-Ultra v40939, SUSFS v2.3.0, KPM | `artifacts/TURBO-SukiSU/` |

---

## Artifacts Structure

All compiled release packages and boot images are organized into dedicated subfolders inside `artifacts/`:

```text
artifacts/
├── NEO-Vanilla/
│   ├── Auraflow-Kernel-NEO-Vanilla-<YYYYMMDD>.zip
│   └── Auraflow-Boot-NEO-Vanilla-<YYYYMMDD>.img
│
├── NEO-SukiSU/
│   ├── Auraflow-Kernel-NEO-SukiSU-v40939-SUSFS-<YYYYMMDD>.zip
│   ├── Auraflow-Boot-NEO-SukiSU-v40939-SUSFS-<YYYYMMDD>.img
│   ├── SukiSU_v4.2.0_Manager.apk
│   └── SukiSU_v4.2.0_Spoofed_Manager.apk
│
├── TURBO-Vanilla/
│   ├── Auraflow-Kernel-TURBO-Vanilla-<YYYYMMDD>.zip
│   └── Auraflow-Boot-TURBO-Vanilla-<YYYYMMDD>.img
│
├── TURBO-SukiSU/
│   ├── Auraflow-Kernel-TURBO-SukiSU-v40939-SUSFS-<YYYYMMDD>.zip
│   ├── Auraflow-Boot-TURBO-SukiSU-v40939-SUSFS-<YYYYMMDD>.img
│   ├── SukiSU_v4.2.0_Manager.apk
│   └── SukiSU_v4.2.0_Spoofed_Manager.apk
│
└── SukiSU-Managers/
    ├── SukiSU_v4.2.0_Manager.apk
    └── SukiSU_v4.2.0_Spoofed_Manager.apk
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
   fastboot flash boot_ab Auraflow-Boot-NEO-SukiSU-v40939-SUSFS-20260921.img
   ```
3. Reboot the phone:
   ```bash
   fastboot reboot
   ```

### SukiSU Ultra Manager Setup (Root Variants)
- For SukiSU variants, install `SukiSU_v4.2.0_Manager.apk` or `SukiSU_v4.2.0_Spoofed_Manager.apk` from the variant folder or `artifacts/SukiSU-Managers/`.
- The Manager is compiled with matching version code `40939` and UAPI `2`, signed with the Auraflow release keystore (embedded into the kernel driver).
- KPM module management, Superuser grants, and SUSFS mount hiding are fully accessible right out of the box without version mismatch warnings.

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

### Build SukiSU-Ultra + SUSFS + KPM Variants
```bash
# Build NEO SukiSU variant
./build_kernel.sh --root neo

# Build TURBO SukiSU variant
./build_kernel.sh --root turbo
```

### Build Both Variants for a Profile
```bash
# Build both Vanilla and SukiSU for NEO
./build_kernel.sh --all neo

# Build both Vanilla and SukiSU for TURBO
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
