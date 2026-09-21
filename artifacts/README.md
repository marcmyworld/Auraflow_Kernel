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

## ReSukiSU & SUSFS & KPM & NoMount Integration

- **KernelSU Implementation**: ReSukiSU v4.2.0 (Build `35159`, UAPI `4`)
- **Mount & Path Hiding**: SUSFS v2.3.0 (`CONFIG_KSU_SUSFS=y`) with inline kernel hooks
- **Kernel Patch Module**: Native in-kernel KPM v0.11.0 implementation (`CONFIG_KPM=y`) with dynamic module registry and loader
- **NoMount Subsystem**: Baked-in NoMount path redirection subsystem (`CONFIG_NOMOUNT=y`) for stealth module injection without mount detection
- **Full Feature Suite Active**: Classic SU command, Kernel umount, ADB Root, SELinux Hide, and SU Logging all functional and enabled
- **Manager Theme Defaults Active Out of the Box**:
  - ✨ Blur
  - 🌊 Floating bottom bar
  - 💎 Liquid glass
  - 🔄 Predictive back gesture (Scale animation)
- **Manager APK Compatibility**:
  - `ReSukiSU_v4.2.0_Manager.apk`: Standard manager package (`com.resukisu.resukisu`), versionCode `35159`, UAPI `4`.
  - `ReSukiSU_v4.2.0_Spoofed_Manager.apk`: Spoofed package (`com.aura.resukisu`) for detection evasion, versionCode `35159`, UAPI `4`.
  - Both APKs are signed with the Auraflow release keystore (`8aa0f658cba545308d65c0aaee8b85f98ad54230d1c9f6065a8e156358d48c09`), recognized by `apk_sign_keys[]` in the kernel driver.

---

## Artifact SHA256 Checksums

### 1. NEO Profile (`6.1.174-Auraflow-NEO-v1.0+`)
- **Vanilla (Non-Root)**:
  - AnyKernel3 Zip: `783554298b75b670de5c6c8a7fd2fab31591ff46bd066be49866e422766e4348` (`Auraflow-Kernel-NEO-Vanilla-20260922.zip`)
  - Standalone Boot: `01cde42a0a5007a94b339d0f96e8f85dd8931b955b09a9c926e19d19e82a9176` (`Auraflow-Boot-NEO-Vanilla-20260922.img`)
- **Root (ReSukiSU + SUSFS + KPM + NoMount)**:
  - AnyKernel3 Zip: `f5ccc2894dce8f0098c4e406cd604b5f7742e39a2125e7caaeaedc324f2831db` (`Auraflow-Kernel-NEO-Root-v35159-SUSFS-20260922.zip`)
  - Standalone Boot: `9554f76a73cd914a68771ec45ae46dffbf60d4acccfb1225175715073c41d2cb` (`Auraflow-Boot-NEO-Root-v35159-SUSFS-20260922.img`)

### 2. TURBO Profile (`6.1.174-Auraflow-TURBO-v1.0+`)
- **Vanilla (Non-Root)**:
  - AnyKernel3 Zip: `8261c5f0ec812ab82ffc3b10dcfff2d4a5e2362ef4aca375a910f8f56afb7b09` (`Auraflow-Kernel-TURBO-Vanilla-20260922.zip`)
  - Standalone Boot: `8fda87d7806dc2f3fb0003697b4912d9b74e50f78002ed7d5f48e38d2824d1a4` (`Auraflow-Boot-TURBO-Vanilla-20260922.img`)
- **Root (ReSukiSU + SUSFS + KPM + NoMount)**:
  - AnyKernel3 Zip: `744206f627eeff62d27834e67576f75b8e65d02c307dc41693ba8c7e41b2ce9a` (`Auraflow-Kernel-TURBO-Root-v35159-SUSFS-20260922.zip`)
  - Standalone Boot: `9c9ee5ad1df51dcdf7db0e866b45f674364e3cc6c241dca399b364d20ce5f626` (`Auraflow-Boot-TURBO-Root-v35159-SUSFS-20260922.img`)

### 3. ReSukiSU Managers
- `ReSukiSU_v4.2.0_Manager.apk`: `7c0a7a6bcb640f3b4522d43345d597c507cf3c0165979a88437335b67b6687bf`
- `ReSukiSU_v4.2.0_Spoofed_Manager.apk`: `16a76aead3ace0f9d386173c59f420a1cf9a5ca36f7f569c9717d4819d52c4c2`

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
   For Root variants, install `ReSukiSU_v4.2.0_Manager.apk` or `ReSukiSU_v4.2.0_Spoofed_Manager.apk` to manage root, modules, and stealth settings.
