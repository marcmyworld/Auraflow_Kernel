# Auraflow Kernel

Custom, high-performance, and security-focused Linux kernel built for **Xiaomi SM8650 / SM8635** unified platforms (`chenfeng` - Redmi Turbo 3, and `peridot` - POCO F6).

---

## Highlights & Features

- **Upstream LTS Base**: Rebased and updated to **Linux 6.1.174 LTS** (`android14-6.1.174_r00`).
- **Unified cliffs / SM8635 Support**: Single unified codebase booting cleanly on both Redmi Turbo 3 (`chenfeng`) and POCO F6 (`peridot`).
- **Compiler Toolchain**: Compiled using **ZyC Clang 16.0.6** with full LLVM integrated assembler (`LLVM_IAS=1`) and ThinLTO.
- **Root & Security Options**:
  - **Non-Root (Vanilla)**: Stock-compliant, unrooted kernel variant for banking apps, enterprise security, and maximum compatibility.
  - **SukiSU-Ultra v4.2.0 (Build 40939)**: Next-generation in-kernel root management solution.
  - **SUSFS v2.3.0 Integration**: Native filesystem and mount isolation with inline kernel hooks (`CONFIG_KSU_SUSFS=y`) to prevent root/module detection.
  - **KPM (Kernel Patch Module)**: Live runtime in-kernel module patching support (`CONFIG_KPM=y`) controllable directly from the SukiSU Manager.
- **Tuned Performance Profiles**:
  - ⚖️ **Balanced** (Default): Perfectly balanced CPU frequency scaling, optimal thermal management, and smooth UI responsiveness for daily usage.
  - 🔋 **Battery**: Energy-conscious governor tuning and delayed ramp-ups for maximized Screen-on-Time (SOT).
  - ⚡ **Performance**: Aggressive scheduler responsiveness, minimal frame drops, and sustained frequencies for heavy gaming and demanding workloads.

---

## Available Variants & Profiles

Auraflow Kernel is provided in 3 performance profiles and 2 root configurations (a total of 6 variants):

| Profile | Variant | Features | Output Folder |
|---|---|---|---|
| **Balanced** | Non-Root (Vanilla) | Stock-like, unrooted, Knox/Play Integrity friendly | `artifacts/Balanced-NonRoot/` |
| **Balanced** | SukiSU + SUSFS + KPM | SukiSU-Ultra 40939, SUSFS 2.3.0, KPM | `artifacts/Balanced-SukiSU-SUSFS/` |
| **Battery** | Non-Root (Vanilla) | Battery-saver governor, unrooted | `artifacts/Battery-NonRoot/` |
| **Battery** | SukiSU + SUSFS + KPM | Battery-saver governor, SukiSU + SUSFS + KPM | `artifacts/Battery-SukiSU-SUSFS/` |
| **Performance** | Non-Root (Vanilla) | High-performance governor, unrooted | `artifacts/Performance-NonRoot/` |
| **Performance** | SukiSU + SUSFS + KPM | High-performance governor, SukiSU + SUSFS + KPM | `artifacts/Performance-SukiSU-SUSFS/` |

---

## Artifacts Organization

All compiled release packages and boot images are organized into dedicated subfolders inside `artifacts/`:

```
artifacts/
├── Balanced-NonRoot/
│   ├── Auraflow-Kernel-Balanced-<TIMESTAMP>.zip
│   └── boot-auraflow-balanced.img
├── Balanced-SukiSU-SUSFS/
│   ├── Auraflow-Kernel-Balanced-SukiSU-SUSFS-<TIMESTAMP>.zip
│   ├── boot-auraflow-balanced-sukisu.img
│   ├── SukiSU_v4.2.0_Manager.apk
│   └── SukiSU_v4.2.0_Spoofed_Manager.apk
├── Battery-NonRoot/
│   ├── Auraflow-Kernel-Battery-<TIMESTAMP>.zip
│   └── boot-auraflow-battery.img
├── Battery-SukiSU-SUSFS/
│   ├── Auraflow-Kernel-Battery-SukiSU-SUSFS-<TIMESTAMP>.zip
│   ├── boot-auraflow-battery-sukisu.img
│   ├── SukiSU_v4.2.0_Manager.apk
│   └── SukiSU_v4.2.0_Spoofed_Manager.apk
├── Performance-NonRoot/
│   ├── Auraflow-Kernel-Performance-<TIMESTAMP>.zip
│   └── boot-auraflow-performance.img
└── Performance-SukiSU-SUSFS/
    ├── Auraflow-Kernel-Performance-SukiSU-SUSFS-<TIMESTAMP>.zip
    ├── boot-auraflow-performance-sukisu.img
    ├── SukiSU_v4.2.0_Manager.apk
    └── SukiSU_v4.2.0_Spoofed_Manager.apk
```

---

## Installation Guide

### Method 1: Custom Recovery (TWRP / OrangeFox) — Recommended
1. Reboot phone to custom recovery.
2. Transfer the desired `Auraflow-Kernel-<Profile>-*.zip` to device storage.
3. Flash the `.zip` file using the recovery flash menu.
4. Reboot system.

### Method 2: Fastboot Boot Image
1. Reboot phone to Fastboot mode (`adb reboot bootloader`).
2. Flash the standalone boot image:
   ```bash
   fastboot flash boot boot-auraflow-<profile>.img
   ```
3. Reboot device:
   ```bash
   fastboot reboot
   ```

### SukiSU Manager Setup (For Root Variants)
- For SukiSU variants, install the matching `SukiSU_v4.2.0_Manager.apk` or `SukiSU_v4.2.0_Spoofed_Manager.apk` located in the variant's folder.
- The manager matches the kernel version code (`40939`) and UAPI (`2`) 1:1, unlocking the full Superuser, Module, and KPM management features without version mismatch warnings.

---

## Building from Source

The build system is orchestrated via `./build_kernel.sh`:

### Build Non-Root (Vanilla) Variants
```bash
# Build Balanced Non-Root (default)
./build_kernel.sh balanced
# or
./build_kernel.sh --vanilla balanced

# Build Battery Non-Root
./build_kernel.sh --vanilla battery

# Build Performance Non-Root
./build_kernel.sh --vanilla performance
```

### Build SukiSU-Ultra + SUSFS + KPM Variants
```bash
# Build Balanced SukiSU-Ultra variant
./build_kernel.sh --root balanced

# Build Battery SukiSU-Ultra variant
./build_kernel.sh --root battery

# Build Performance SukiSU-Ultra variant
./build_kernel.sh --root performance
```

### Build All Types for a Profile
```bash
# Build both Non-Root and SukiSU for Balanced
./build_kernel.sh --all balanced

# Build both Non-Root and SukiSU for Battery
./build_kernel.sh --all battery

# Build both Non-Root and SukiSU for Performance
./build_kernel.sh --all performance
```

### Build Everything (All 6 Variants)
```bash
./build_kernel.sh --all
```

---

## Hardware & Compatibility

- **Devices**:
  - Xiaomi Redmi Turbo 3 (`chenfeng`)
  - POCO F6 (`peridot`)
- **Platform**: Qualcomm Snapdragon 8s Gen 3 (SM8635 / SM8650-compatible architecture)
- **Supported Android Versions**: Android 14 (HyperOS, AOSP, Evolution X, LineageOS)
