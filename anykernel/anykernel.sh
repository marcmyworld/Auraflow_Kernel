### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Auraflow Kernel for SM8635 / cliffs (chenfeng & peridot)
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=chenfeng
device.name2=chenfengin
device.name3=peridot
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot shell variables
block=boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto
no_magisk_check=1

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

kernel_version=$(cat /proc/version | awk '{print $3}')

# Dynamic device identification
device_codename=$(getprop ro.product.device 2>/dev/null)
[ -z "$device_codename" ] && device_codename=$(getprop ro.build.product 2>/dev/null)
[ -z "$device_codename" ] && device_codename=$(getprop ro.product.vendor.device 2>/dev/null)
[ -z "$device_codename" ] && device_codename=$(getprop ro.vendor.product.device 2>/dev/null)

model_name=$(getprop ro.product.model 2>/dev/null)
[ -z "$model_name" ] && model_name=$(getprop ro.product.vendor.model 2>/dev/null)

case "$device_codename" in
  chenfeng|chenfengin)
    display_device="Xiaomi 14 Civi / Civi 4 Pro"
    ;;
  peridot)
    display_device="POCO F6 / Redmi Turbo 3"
    ;;
  *)
    if [ -n "$model_name" ]; then
      display_device="$model_name"
    else
      display_device="SM8635 (cliffs)"
    fi
    ;;
esac

ui_print " "
ui_print "========================================"
ui_print "            AURAFLOW KERNEL             "
ui_print "        SM8635 / cliffs Unified         "
ui_print "========================================"
ui_print " "
ui_print "- Detected Device:  $display_device ($device_codename)"
ui_print "- Current Kernel:   $kernel_version"
ui_print "- Target Partition: /dev/block/by-name/boot"
ui_print "- Installing Auraflow Kernel Image..."

# boot install (Android 14 GKI device with init_boot partition)
split_boot
flash_boot
## end boot install
