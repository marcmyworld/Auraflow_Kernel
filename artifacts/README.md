# Auraflow Kernel - Release Artifacts

Unified kernel builds for **Snapdragon 8s Gen 3 (`SM8635 / cliffs`)**, fully compatible with:
- **Xiaomi 14 Civi / Civi 4 Pro (`chenfeng`)**
- **POCO F6 / Redmi Turbo 3 (`peridot`)**

- Upstream Base: **Linux 6.1.174 LTS (Android 14 GKI / `android14-6.1.174_r00`)** with dynamic sublevel auto-detection
- Compiler: **ZyC Clang 16.0.6 (ThinLTO, LLVM IAS)**
- Profile Strategy: **2 Profiles × 2 Root Modes = 4 Release Targets**
- Kernel Release Strings:
  - 🌟 **NEO Profile**: `6.1.174-Auraflow-NEO-v1.0+`
  - 🚀 **TURBO Profile**: `6.1.174-Auraflow-TURBO-v1.0+`
- Supported Android OS: **Android 14, 15, 16, 17, and all above versions (Android 14+)**
- Distribution: **Flashable AnyKernel3 Zips Only** (Standalone `boot.img` removed)

---

## Directory Structure

```text
artifacts/
├── NEO-Vanilla/
│   └── Auraflow-Kernel-NEO-Vanilla-20260922.zip
│
├── NEO-Root/
│   ├── Auraflow-Kernel-NEO-Root-v35159-SUSFS-20260922.zip
│   └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
│
├── TURBO-Vanilla/
│   └── Auraflow-Kernel-TURBO-Vanilla-20260922.zip
│
├── TURBO-Root/
│   ├── Auraflow-Kernel-TURBO-Root-v35159-SUSFS-20260922.zip
│   └── ReSukiSU_v4.2.0_Spoofed_Manager.apk
│
└── Manager/ (aliases: Managers/, ReSukiSU-Managers/)
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
- **Manager APK Distribution**:
  - `NEO-Root/` and `TURBO-Root/`: Bundled with `ReSukiSU_v4.2.0_Spoofed_Manager.apk` (`com.aura.resukisu`) for stealth.
  - `Manager/`: Houses both `ReSukiSU_v4.2.0_Manager.apk` (`com.resukisu.resukisu`) and `ReSukiSU_v4.2.0_Spoofed_Manager.apk`.
  - Both APKs are signed with the Auraflow release keystore (`8aa0f658cba545308d65c0aaee8b85f98ad54230d1c9f6065a8e156358d48c09`), recognized by `apk_sign_keys[]` in the kernel driver.

---

## Artifact SHA256 Checksums

### 1. NEO Profile (`6.1.174-Auraflow-NEO-v1.0+`)
- **Vanilla (Non-Root)**:
  - AnyKernel3 Zip: `b5d0cc572b01586b25136d742b080fc408738bbf4e9a7a67eddc3189f326fe10` (`Auraflow-Kernel-NEO-Vanilla-20260922.zip`)
- **Root (ReSukiSU + SUSFS + NoMount)**:
  - AnyKernel3 Zip: `dd1796c0174c8a75f22d9d002211e46411d937f15e7a9464307c8b2ec53bf2d9` (`Auraflow-Kernel-NEO-Root-v35159-SUSFS-20260922.zip`)
  - Spoofed Manager: `96f74832449c2de9b55ca1630dae0dd7568b13e0e552c8f91abbd5c8d8b67e0c` (`ReSukiSU_v4.2.0_Spoofed_Manager.apk`)

### 2. TURBO Profile (`6.1.174-Auraflow-TURBO-v1.0+`)
- **Vanilla (Non-Root)**:
  - AnyKernel3 Zip: `96f5690f811294a3933c557c2346722bcace7526e88cd77985660ef0660bfefa` (`Auraflow-Kernel-TURBO-Vanilla-20260922.zip`)
- **Root (ReSukiSU + SUSFS + NoMount)**:
  - AnyKernel3 Zip: `8343a058c602b1a8f5f45f46a23938d6422d392a9c809d9879a1b60608b2ce31` (`Auraflow-Kernel-TURBO-Root-v35159-SUSFS-20260922.zip`)
  - Spoofed Manager: `96f74832449c2de9b55ca1630dae0dd7568b13e0e552c8f91abbd5c8d8b67e0c` (`ReSukiSU_v4.2.0_Spoofed_Manager.apk`)

### 3. Central Manager Suite (`artifacts/Manager/`)
- `ReSukiSU_v4.2.0_Manager.apk`: `95fec09bc7ea8340596a807b46fe0dd62e1b5d03df854a19885efb570df199e6`
- `ReSukiSU_v4.2.0_Spoofed_Manager.apk`: `96f74832449c2de9b55ca1630dae0dd7568b13e0e552c8f91abbd5c8d8b67e0c`

---

## Flashing Instructions

1. **Custom Recovery (TWRP / OrangeFox)**:
   Flash `Auraflow-Kernel-<Profile>-*.zip` via Install menu.
2. **Manager Installation**:
   For Root variants, install `ReSukiSU_v4.2.0_Spoofed_Manager.apk` from the variant folder or either manager APK from `artifacts/Manager/`.
