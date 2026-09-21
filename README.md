# Auraflow Kernel

Custom, high-performance, and security-focused Linux kernel built for **Xiaomi SM8650 / SM8635** unified platforms (**Xiaomi 14 Civi / Civi 4 Pro** `chenfeng` and **POCO F6 / Redmi Turbo 3** `peridot`).

---

## Highlights & Features

- **Upstream LTS Base & Dynamic GKI Sublevel**: Rebased and updated to **Linux 6.1.174 LTS** (`android14-6.1.174_r00`). The build pipeline automatically detects and selects the active GKI sublevel directly from `Makefile`, ensuring zero configuration drift when upstream 6.1.y LTS patches are merged.
- **Centralized Release Versioning**: Auraflow versioning (e.g. `v1.0+`) is centrally managed via `AURAFLOW_VERSION`, allowing seamless version bumping without editing individual defconfigs.
- **Kernel Version Release String**:
  - 🌟 **NEO**: `6.1.174-Auraflow-NEO-v1.0+`
  - 🚀 **TURBO**: `6.1.174-Auraflow-TURBO-v1.0+`
  Full visible string natively reported in `uname -r` and Android Settings.
- **Unified cliffs / SM8635 Architecture**: Single unified codebase booting cleanly across both **Xiaomi 14 Civi / Civi 4 Pro** (`chenfeng`) and **POCO F6 / Redmi Turbo 3** (`peridot`).
- **Compiler Toolchain**: Built with **ZyC Clang 16.0.6** utilizing the full LLVM integrated assembler (`LLVM_IAS=1`) and ThinLTO.
- **Pure AnyKernel3 Distribution**: Release packages are built exclusively as flashable AnyKernel3 archives (`.zip`), eliminating standalone boot image flashing and preserving ramdisk/init integrity.
- **Root, Security & Stealth Stack**:
  - **Vanilla (Non-Root)**: Stock-compliant, unrooted kernel variant ideal for banking applications, enterprise compliance, and Play Integrity.
  - **ReSukiSU v4.2.0 (Build 35159, UAPI v4)**: Modern, multi-manager in-kernel root management solution ([ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)).
  - **SUSFS v2.3.0 Integration**: Native filesystem and mount isolation with inline kernel hooks (`CONFIG_KSU_SUSFS=y`) providing stealth root hiding.
  - **NoMount Subsystem**: Baked-in [NoMount](https://github.com/maxsteeel/nomount) path redirection subsystem (`CONFIG_NOMOUNT=y`) enabling stealth root modules and file injection without mounting filesystem overlays.
  - **Full Feature Suite Active**: Classic SU compatibility, Kernel umount, ADB Root, SELinux Hide, and SU Logging all fully registered and functional (not greyed out).
- **Modern Profile Philosophy**:
  - 🌟 **NEO** (Default): Intelligent daily driver delivering optimal power efficiency and buttery smoothness. Configured with power-efficient workqueues (`CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y`), balanced energy curve governor (`CONFIG_KP_DEFAULT_MODE=2`), responsive touch boost, and extended battery life.
  - 🚀 **TURBO**: High, plausibly feasible sustained performance focusing on low-latency scheduling, sustained CPU clocks, and rapid thread wakeups for heavy gaming and intensive multitasking (`CONFIG_KP_DEFAULT_MODE=3`, low-latency workqueues).
- **ReSukiSU Manager Suite**:
  - Stable, pristine Material 3 interface without experimental UI overrides.
  - Variant root packages include the spoofed stealth manager (`ReSukiSU_v4.2.0_Spoofed_Manager.apk`, `com.aura.resukisu`).
  - The central `artifacts/Manager/` folder houses both the original (`com.resukisu.resukisu`) and spoofed managers.
  - Pre-signed with the Auraflow release key recognized by `apk_sign_keys[]` in the kernel driver.

---

## Available Variants & Profiles

Auraflow Kernel is organized into **2 performance profiles** across **2 root modes** (2×2 = 4 release targets):

| Profile | Mode | Kernel Release (`uname -r`) | Key Configurations | Output Folder |
|---|---|---|---|---|
| **NEO** | Vanilla (Non-Root) | `6.1.174-Auraflow-NEO-v1.0+` | Power-efficient workqueues, balanced energy curve, unrooted | `artifacts/NEO-Vanilla/` |
| **NEO** | Root (ReSukiSU + SUSFS + NoMount) | `6.1.174-Auraflow-NEO-v1.0+` | Power-efficient workqueues, ReSukiSU v35159, SUSFS v2.3.0, NoMount | `artifacts/NEO-Root/` |
| **TURBO** | Vanilla (Non-Root) | `6.1.174-Auraflow-TURBO-v1.0+` | Low-latency scheduling, sustained high clocks, unrooted | `artifacts/TURBO-Vanilla/` |
| **TURBO** | Root (ReSukiSU + SUSFS + NoMount) | `6.1.174-Auraflow-TURBO-v1.0+` | Low-latency scheduling, ReSukiSU v35159, SUSFS v2.3.0, NoMount | `artifacts/TURBO-Root/` |

---

## Artifacts Structure

Release artifacts are distributed exclusively as AnyKernel3 flashable archives and manager APKs inside `artifacts/`:

```text
artifacts/
├── NEO-Vanilla/
│   └── Auraflow-Kernel-NEO-Vanilla-<YYYYMMDD>.zip
│
├── NEO-Root/
│   ├── Auraflow-Kernel-NEO-Root-v35159-SUSFS-<YYYYMMDD>.zip
│   └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
│
├── TURBO-Vanilla/
│   └── Auraflow-Kernel-TURBO-Vanilla-<YYYYMMDD>.zip
│
├── TURBO-Root/
│   ├── Auraflow-Kernel-TURBO-Root-v35159-SUSFS-<YYYYMMDD>.zip
│   └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
│
└── Manager/ (aliases: Managers/, ReSukiSU-Managers/)
    ├── ReSukiSU_v4.2.0_Manager.apk
    └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
```

---

## Installation Guide

### Custom Recovery (TWRP / OrangeFox)
1. Reboot the device into custom recovery (TWRP / OrangeFox).
2. Copy the desired `Auraflow-Kernel-<Profile>-*.zip` to internal storage or USB-OTG.
3. Flash the `.zip` archive via the recovery install menu. AnyKernel3 will automatically identify your device (`chenfeng` or `peridot`), unpack the current boot partition, inject the Auraflow kernel Image, and repack without disturbing your ramdisk.
4. Reboot to system.

### ReSukiSU Manager Setup (Root Variants)
- For Root variants, install `ReSukiSU_v4.2.0_Spoofed_Manager.apk` included in the variant directory (`NEO-Root/` or `TURBO-Root/`).
- Alternatively, you can install the original package `ReSukiSU_v4.2.0_Manager.apk` from `artifacts/Manager/`.
- Both packages are pre-signed with the Auraflow release keystore (`8aa0f658cba545308d65c0aaee8b85f98ad54230d1c9f6065a8e156358d48c09`), recognized by `apk_sign_keys[]` in the kernel driver.
- Superuser management, NoMount path redirection, and SUSFS stealth features work out of the box.

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

### Build Root (ReSukiSU + SUSFS + NoMount) Variants
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

### Centralized Version Management & Upstream LTS Check
```bash
# Bump Auraflow release version across files and defconfigs (e.g. 1.1)
./build_kernel.sh --bump-version 1.1

# Check current local GKI sublevel against kernel.org Linux 6.1.y LTS
./build_kernel.sh --check-lts
```

---

## Hardware & OS Compatibility

- **Target Devices**:
  - **Xiaomi 14 Civi / Civi 4 Pro** (`chenfeng` / `chenfengin`)
  - **POCO F6 / Redmi Turbo 3** (`peridot`)
- **SoC**: Qualcomm Snapdragon 8s Gen 3 (`SM8635` / `cliffs`)
- **Supported Android OS**: **Android 14, 15, 16, 17, and all above versions (Android 14+)**, fully supporting:
  - Android 14
  - Android 15 / Android 15 QPR
  - Android 16
  - Android 17
  - All future Android releases
  - Xiaomi HyperOS 1.0 & HyperOS 2.0
  - AOSP, LineageOS, Evolution X, PixelOS, and all modern custom ROMs
