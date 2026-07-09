SLOT_SELECT=all
### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Alioth Kernel for Poco F3/Redmi K40/Mi 11X
do.devicecheck=1
device.name1=alioth
device.name2=mi 11x
device.name3=redmi k40
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
supported.versions=
supported.patchlevels=
'; } # end properties


### AnyKernel install

# boot shell variables
BLOCK=boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

NO_BLOCK_DISPLAY=1

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
# === Dual-Slot Flash (proven from pocof3) ===
DUAL_SLOT=1;
OTHER_BLOCK="";
if [ "$SLOT" ]; then
  ui_print "  -----------------------------------------";
  ui_print "  Dual-Slot Flash Mode";
  ui_print "  -----------------------------------------";
  ui_print "  Default: flash BOTH A/B slots.";
  ui_print "  Hold VOLUME UP to flash active slot only.";
  ui_print "  -----------------------------------------";
  if timeout 10 getevent -c5 2>/dev/null | grep -qm1 '0001 0073'; then
    DUAL_SLOT=0;
    ui_print "  -> VOLUME UP pressed: active slot only!";
  else
    ui_print "  -> Flashing BOTH slots!";
  fi;
  ui_print "  -----------------------------------------";
  case "$BLOCK" in
    *_a) OTHER_BLOCK="${BLOCK%_a}_b";;
    *_b) OTHER_BLOCK="${BLOCK%_b}_a";;
  esac;
  if [ "$OTHER_BLOCK" = "$BLOCK" ] || [ -z "$OTHER_BLOCK" ]; then
    OTHER_BLOCK="";
    ui_print "  Warning: could not determine other slot block device.";
  else
    ui_print "  Other slot: $OTHER_BLOCK";
  fi;
fi;
split_boot;
flash_boot;
# Flash both slots reliably (post-flash_boot)
if [ "$DUAL_SLOT" = "1" ] && [ -f "${AKHOME}/boot-new.img" ]; then
  IMG="${AKHOME}/boot-new.img";
  ui_print "  -> Flashing active slot ($BLOCK)...";
  if ! dd if="$IMG" of="$BLOCK" bs=4096 2>/dev/null; then
    ui_print "  WARNING: dd to active slot failed!";
  fi;
  if [ "$OTHER_BLOCK" ]; then
    ui_print "  -> Flashing other slot ($OTHER_BLOCK)...";
    if ! dd if="$IMG" of="$OTHER_BLOCK" bs=4096 2>/dev/null; then
      ui_print "  WARNING: dd to other slot failed!";
    fi;
  fi;
fi;
## end boot install
