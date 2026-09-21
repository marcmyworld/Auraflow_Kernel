# Auraflow Kernel - Release Artifacts

Unified kernel builds for **Snapdragon 8s Gen 3 (`SM8635 / cliffs`)**, fully compatible with:
- **Xiaomi 14 Civi / Civi 4 Pro (`chenfeng`)**
- **POCO F6 / Redmi Turbo 3 (`peridot`)**

- Upstream Base: **Linux 6.1.174 LTS (Android 14 GKI / `android14-6.1.174_r00`)**
- Compiler: **ZyC Clang 16.0.6 (ThinLTO, LLVM IAS)**
- Profile Strategy: **2 Profiles × 2 Root Modes = 4 Release Targets**
- Kernel Release Strings:
  - 🌟 **NEO Profile**: `6.1.174-Auraflow-NEO-v1.0+`
  - 🚀 **TURBO Profile**: `6.1.174-Auraflow-TURBO-v1.0+`
- Supported Android OS: **Android 14 and all above versions (Android 14+)**

---

## Directory Structure

```text
artifacts/
├── NEO-Vanilla/
│   ├── Auraflow-Kernel-NEO-Vanilla-20260922.zip
│   └── Auraflow-Boot-NEO-Vanilla-20260922.img
│
├── NEO-Root/
│   ├── Auraflow-Kernel-NEO-Root-v35159-SUSFS-20260922.zip
│   ├── Auraflow-Boot-NEO-Root-v35159-SUSFS-20260922.img
│   ├── ReSukiSU_v4.2.0_Manager.apk
│   └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
│
├── TURBO-Vanilla/
│   ├── Auraflow-Kernel-TURBO-Vanilla-20260922.zip
│   └── Auraflow-Boot-TURBO-Vanilla-20260922.img
│
├── TURBO-Root/
│   ├── Auraflow-Kernel-TURBO-Root-v35159-SUSFS-20260922.zip
│   ├── Auraflow-Boot-TURBO-Root-v35159-SUSFS-20260922.img
│   ├── ReSukiSU_v4.2.0_Manager.apk
│   └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
│
└── ReSukiSU-Managers/
    ├── ReSukiSU_v4.2.0_Manager.apk
    └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
```

---

## ReSukiSU & SUSFS & NoMount Integration

- **KernelSU Implementation**: ReSukiSU v4.2.0 (Build `35159`, UAPI `4`)
- **Mount & Path Hiding**: SUSFS v2.3.0 (`CONFIG_KSU_SUSFS=y`) with inline kernel hooks
- **NoMount Subsystem**: Baked-in NoMount path redirection subsystem (`CONFIG_NOMOUNT=y`) for stealth module injection without mount detection
- **Full Feature Suite Active**: Classic SU command, Kernel umount, ADB Root, SELinux Hide, and SU Logging all functional and enabled
- **Manager Experience**: Clean, stable upstream Material 3 interface
- **Manager APK Compatibility**:
  - `ReSukiSU_v4.2.0_Manager.apk`: Standard manager package (`com.resukisu.resukisu`), versionCode `35159`, UAPI `4`.
  - `ReSukiSU_v4.2.0_Spoofed_Manager.apk`: Spoofed package (`com.aura.resukisu`) for detection evasion, versionCode `35159`, UAPI `4`.
  - Both APKs are signed with the Auraflow release keystore (`8aa0f658cba545308d65c0aaee8b85f98ad54230d1c9f6065a8e156358d48c09`), recognized by `apk_sign_keys[]` in the kernel driver.

---

## Artifact SHA256 Checksums

### 1. NEO Profile (`6.1.174-Auraflow-NEO-v1.0+`)
- **Vanilla (Non-Root)**:
  - AnyKernel3 Zip: `1e0e45ba7847e1b5dceb1f2c822257965923666f17ec37e0027cffb212261a8b` (`Auraflow-Kernel-NEO-Vanilla-20260922.zip`)
  - Standalone Boot: `b55c3db3cb2826f2906de1f19ee5745dfc527347a4948286adf100d7058916c8` (`Auraflow-Boot-NEO-Vanilla-20260922.img`)
- **Root (ReSukiSU + SUSFS + NoMount)**:
  - AnyKernel3 Zip: `347a490c4280e2f84beea31951411567f56399447a328f670d07172b9971f537` (`Auraflow-Kernel-NEO-Root-v35159-SUSFS-20260922.zip`)
  - Standalone Boot: `f93c9402dcd94ea1a95873eb779b4580bbcd49251125b75dd5184d58c0a3e191` (`Auraflow-Boot-NEO-Root-v35159-SUSFS-20260922.img`)

### 2. TURBO Profile (`6.1.174-Auraflow-TURBO-v1.0+`)
- **Vanilla (Non-Root)**:
  - AnyKernel3 Zip: `28bcd6948beaee4cf21e105788fd52cc5725b2b110e02c532e3b8703493218c9` (`Auraflow-Kernel-TURBO-Vanilla-20260922.zip`)
  - Standalone Boot: `d1fba52ed4ca331ad6a4bd062d94315516397b33c3e4c5d6f0769c97c6dac862` (`Auraflow-Boot-TURBO-Vanilla-20260922.img`)
- **Root (ReSukiSU + SUSFS + NoMount)**:
  - AnyKernel3 Zip: `4040b8bb7b10ec03c3d29abe6bc87f6cd48991ceeb7902bb4cfd290095a27701` (`Auraflow-Kernel-TURBO-Root-v35159-SUSFS-20260922.zip`)
  - Standalone Boot: `39fa1b21fee932a3b588ad1e1edd105a13ee2648a9448d6027a6b4ea5301c8c8` (`Auraflow-Boot-TURBO-Root-v35159-SUSFS-20260922.img`)

### 3. ReSukiSU Managers
- `ReSukiSU_v4.2.0_Manager.apk`: `95fec09bc7ea8340596a807b46fe0dd62e1b5d03df854a19885efb570df199e6`
- `ReSukiSU_v4.2.0_Spoofed_Manager.apk`: `96f74832449c2de9b55ca1630dae0dd7568b13e0e552c8f91abbd5c8d8b67e0c`

---

## Flashing Instructions

1. **Custom Recovery (TWRP / OrangeFox)**:
   Flash `Auraflow-Kernel-<Profile>-*.zip` via Install menu.
2. **Fastboot**:
   Flash the standalone boot image across both slots:
   ```bash
   fastboot flash boot_ab <boot_image_name>.img
   ```
3. **Manager Installation**:
   For Root variants, install `ReSukiSU_v4.2.0_Manager.apk` or `ReSukiSU_v4.2.0_Spoofed_Manager.apk` to manage root and stealth settings.
