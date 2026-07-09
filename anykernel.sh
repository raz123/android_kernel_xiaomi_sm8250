SLOT_SELECT=all
# AnyKernel3 Ramdisk Mod Script
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
BLOCK=boot
IS_SLOT_DEVICE=1
RAMDISK_COMPRESSION=auto
PATCH_VBMETA_FLAG=auto
'; }
. tools/ak3-core.sh
split_boot
patch_cmdline zswap.enabled 1
patch_cmdline zswap.compressor lz4
patch_cmdline zswap.zpool z3fold
patch_cmdline zswap.max_pool_percent 25
flash_boot
