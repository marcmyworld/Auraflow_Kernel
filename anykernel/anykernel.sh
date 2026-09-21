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

# Robust device identification for Recovery environments
get_device_prop() {
  local val=""
  for cmd in getprop /system/bin/getprop /bin/getprop "toybox getprop" resetprop; do
    if $cmd "$1" >/dev/null 2>&1; then
      val=$($cmd "$1" 2>/dev/null)
      [ -n "$val" ] && break
    fi
  done
  echo "$val"
}

device_codename=""
for prop in ro.product.device ro.build.product ro.product.vendor.device ro.vendor.product.device ro.product.name; do
  device_codename=$(get_device_prop "$prop")
  [ -n "$device_codename" ] && break
done

# Fallback 1: Device-Tree model from hardware
dt_model=""
if [ -f /proc/device-tree/model ]; then
  dt_model=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null)
fi

# Fallback 2: /proc/cmdline
if [ -z "$device_codename" ] && [ -f /proc/cmdline ]; then
  device_codename=$(grep -oE 'androidboot\.(device|product\.device|hardware)=[^ ]+' /proc/cmdline 2>/dev/null | head -n1 | cut -d= -f2)
fi

# Fallback 3: Search recovery property files
if [ -z "$device_codename" ]; then
  for f in /prop.default /default.prop /system/build.prop /vendor/build.prop; do
    if [ -f "$f" ]; then
      for prop in ro.product.device ro.build.product ro.product.vendor.device; do
        device_codename=$(grep -E "^${prop}=" "$f" 2>/dev/null | head -n1 | cut -d= -f2-)
        [ -n "$device_codename" ] && break 2
      done
    fi
  done
fi

# If still not found from properties, deduce from Device Tree model string
if [ -z "$device_codename" ] && [ -n "$dt_model" ]; then
  case "$(echo "$dt_model" | tr '[:upper:]' '[:lower:]')" in
    *chenfeng*) device_codename="chenfeng" ;;
    *peridot*)  device_codename="peridot" ;;
  esac
fi

# Determine display name
case "$device_codename" in
  chenfeng|chenfengin)
    display_device="Xiaomi 14 Civi / Civi 4 Pro"
    device_label="chenfeng"
    ;;
  peridot)
    display_device="POCO F6 / Redmi Turbo 3"
    device_label="peridot"
    ;;
  *)
    if [ -n "$dt_model" ]; then
      case "$(echo "$dt_model" | tr '[:upper:]' '[:lower:]')" in
        *chenfeng*)
          display_device="Xiaomi 14 Civi / Civi 4 Pro"
          device_label="chenfeng"
          ;;
        *peridot*)
          display_device="POCO F6 / Redmi Turbo 3"
          device_label="peridot"
          ;;
        *)
          display_device="$dt_model"
          device_label="${device_codename:-cliffs}"
          ;;
      esac
    else
      display_device="SM8635 / cliffs Device"
      device_label="${device_codename:-cliffs}"
    fi
    ;;
esac

ui_print " "
ui_print "========================================"
ui_print "            AURAFLOW KERNEL             "
ui_print "        SM8635 / cliffs Unified         "
ui_print "========================================"
ui_print " "
ui_print "- Variant:          VARIANT_PLACEHOLDER"
ui_print "- Detected Device:  $display_device ($device_label)"
ui_print "- Current Kernel:   $kernel_version"
ui_print "- Target Partition: /dev/block/by-name/boot"
ui_print "- Installing Auraflow Kernel Image..."

# boot install (Android 14 GKI device with init_boot partition)
split_boot
flash_boot
## end boot install
