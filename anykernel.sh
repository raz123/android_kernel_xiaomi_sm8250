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

## Select the correct image to flash
userflavor="$(file_getprop /system/build.prop "ro.build.flavor")";
case "$userflavor" in
    missi*|qssi*) os="miui"; os_string="MIUI ROM";;
    *) os="aosp"; os_string="AOSP ROM";;
esac;
ui_print "  -> $os_string is detected!";
if [ -f $AKHOME/kernels/$os/Image ] && [ -f $AKHOME/kernels/$os/dtb ] && [ -f $AKHOME/kernels/$os/dtbo.img ]; then
    mv $AKHOME/kernels/$os/Image $AKHOME/Image;
    mv $AKHOME/kernels/$os/dtb $AKHOME/dtb;
    mv $AKHOME/kernels/$os/dtbo.img $AKHOME/dtbo.img;
else
    ui_print "  -> There is no kernel for $os_string in this zip! Aborting...";
    ui_print "  -> Please check that you have the correct kernel zip!";
    exit 1;
fi;

# flash
split_boot;
flash_boot;
