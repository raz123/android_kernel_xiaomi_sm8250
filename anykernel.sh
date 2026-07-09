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

# flash
split_boot;
flash_boot;
