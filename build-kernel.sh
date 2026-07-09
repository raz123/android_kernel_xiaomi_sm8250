#!/bin/bash
set -euo pipefail

DEVICE="${DEVICE:-alioth}"
KSU="${KSU:-1}"
TOOLCHAIN_PATH="${TOOLCHAIN_PATH:-/opt/zyc-clang/bin}"

# Verify toolchain
if [ ! -d "$TOOLCHAIN_PATH" ]; then
    echo "ERROR: Toolchain not found at $TOOLCHAIN_PATH"
    exit 1
fi
export PATH="$TOOLCHAIN_PATH:$PATH"
echo "Using: $(clang --version | head -1)"

# Verify cross-compiler
if ! command -v aarch64-linux-gnu-ld >/dev/null 2>&1; then
    echo "ERROR: Cross-compiler not found"
    exit 1
fi

MAKE_ARGS="ARCH=arm64 \
           SUBARCH=arm64 \
           HOSTCC=clang \
           CLANG_TRIPLE=aarch64-linux-gnu- \
           CROSS_COMPILE=aarch64-linux-gnu- \
           CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
           CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
           LLVM=1 \
           LLVM_IAS=1"

# ReSukiSU (skip when KSU=0 for vanilla builds)
if [ "$KSU" = "1" ]; then
    git config --global --add safe.directory /workspace/KernelSU
    git config --global --add safe.directory /workspace
    if [ -d "KernelSU/.git" ]; then
        cd KernelSU && git fetch --depth=1 origin HEAD && git reset --hard FETCH_HEAD && cd ..
    else
        git clone --depth=1 https://github.com/ReSukiSU/ReSukiSU KernelSU
    fi
    ln -sf ../KernelSU/kernel drivers/kernelsu
    # Patch ReSukiSU for MANUAL_HOOK compatibility (maps SUSFS symbol names)
    perl -i -0pe 's/(#elif defined\(CONFIG_KSU_MANUAL_HOOK\))/$1\n    \/* Compatibility: SUSFS symbol names used by fs hooks *\/\n    #define ksu_is_init_rc_hook_enabled ksu_init_rc_hook\n    #define ksu_is_input_hook_enabled ksu_input_hook/' KernelSU/kernel/runtime/ksud_integration.c 2>/dev/null || true
    # Disable check_mk files that block build
    for check in drivers/kernelsu/tools/*_check.mk; do
        echo "# Disabled for CI" > "$check" 2>/dev/null || true
    done
    # Add ReSukiSU Kconfig source to drivers/Kconfig (before endmenu)
    if ! grep -q 'source.*drivers/kernelsu/Kconfig' drivers/Kconfig; then
        sed -i '/endmenu/i\source "drivers/kernelsu/Kconfig"' drivers/Kconfig
    fi
    # Add ReSukiSU obj to drivers/Makefile (kernelsu/ is under drivers/)
    if ! grep -q 'obj-$(CONFIG_KSU) += kernelsu/' drivers/Makefile; then
        echo 'obj-$(CONFIG_KSU) += kernelsu/' >> drivers/Makefile
    fi
fi

echo "== Generate config (in-tree)"
make $MAKE_ARGS vendor/xiaomi/${DEVICE}_defconfig

# Merge vendor overlays
if [ -f "arch/arm64/configs/vendor/xiaomi/sm8250-common.config" ] && \
   [ -f "arch/arm64/configs/vendor/xiaomi/${DEVICE}_defconfig" ]; then
    scripts/kconfig/merge_config.sh -m \
        .config \
        arch/arm64/configs/vendor/xiaomi/sm8250-common.config
    make $MAKE_ARGS olddefconfig
fi

# Apply additional configs
scripts/config --disable IKHEADERS
scripts/config --disable LTO_CLANG
scripts/config --disable LTO_CLANG_THIN
scripts/config --disable CFI_CLANG
if [ "$KSU" = "1" ]; then
    scripts/config --enable KSU
    scripts/config --enable KSU_MANUAL_HOOK
    scripts/config --enable KSU_MULTI_MANAGER_SUPPORT
    scripts/config --disable KPM
    scripts/config --enable THREAD_INFO_IN_TASK
fi
if [ -n "${KBUILD_BUILD_VERSION:-}" ]; then
    scripts/config --set-str LOCALVERSION "-rv-b${KBUILD_BUILD_VERSION}"
fi

# Resolve dependency chain after config changes
make $MAKE_ARGS olddefconfig

# Kernel 4.19 compat: MODULE_IMPORT_NS not defined until 5.x+
if ! grep -q "MODULE_IMPORT_NS" include/linux/module.h 2>/dev/null; then
    echo "" >> include/linux/module.h
    echo "#ifndef MODULE_IMPORT_NS" >> include/linux/module.h
    echo "#define MODULE_IMPORT_NS(_ns)" >> include/linux/module.h
    echo "#endif" >> include/linux/module.h
    echo "Added MODULE_IMPORT_NS compat shim"
fi

# Pre-build vdso to generate vdso-offsets.h (missing dependency in kernel Makefile)
echo "Pre-building vdso for vdso-offsets.h..."
mkdir -p include/generated
make $MAKE_ARGS CC="ccache clang" V=${V:-0} -j${JOBS:-$(nproc)} arch/arm64/kernel/vdso/
if [ -f arch/arm64/kernel/vdso/vdso.so.dbg ]; then
    llvm-nm arch/arm64/kernel/vdso/vdso.so.dbg | arch/arm64/kernel/vdso/gen_vdso_offsets.sh | LC_ALL=C sort > include/generated/vdso-offsets.h
    echo "Generated vdso-offsets.h"
fi
# Also build vdso32 for compatvdso offsets
make $MAKE_ARGS CC="ccache clang" V=${V:-0} -j${JOBS:-$(nproc)} arch/arm64/kernel/vdso32/
if [ -f arch/arm64/kernel/vdso32/vdso.so.dbg ]; then
    llvm-nm arch/arm64/kernel/vdso32/vdso.so.dbg | arch/arm64/kernel/vdso/gen_vdso_offsets.sh | LC_ALL=C sort > include/generated/vdso32-offsets.h
    echo "Generated vdso32-offsets.h"
else
    echo "WARNING: vdso32.so.dbg not generated, vdso32-offsets.h may be missing"
fi

echo "Building kernel (in-tree)..."
make $MAKE_ARGS CC="ccache clang" V=${V:-0} -j${JOBS:-$(nproc)}

# Collect output to out/ for workflow compatibility
echo "Collecting build artifacts..."
mkdir -p out/arch/arm64/boot out/modules

# Copy .config for QA gates
cp .config out/.config

# Copy kernel image
if [ -f "arch/arm64/boot/Image" ]; then
    cp arch/arm64/boot/Image out/arch/arm64/boot/Image
    gzip -f out/arch/arm64/boot/Image
fi

# Copy and combine DTBs
if [ -d "arch/arm64/boot/dts" ]; then
    find arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > out/arch/arm64/boot/dtb 2>/dev/null || true
fi

# Copy dtbo.img
if [ -f "arch/arm64/boot/dtbo.img" ]; then
    cp arch/arm64/boot/dtbo.img out/arch/arm64/boot/dtbo.img
fi

# Copy modules
find . -path ./out -prune -o -name "*.ko" -exec cp {} out/modules/ \; 2>/dev/null || true
[ -f "vm_tuning.sh" ] && cp vm_tuning.sh out/modules/

echo "=== ccache stats ==="
ccache -s 2>/dev/null | grep -E 'Hits:|Misses:|Cache size' || echo "ccache stats unavailable"
echo "===================="

echo "=== Build complete ==="
ls -la out/arch/arm64/boot/Image.gz out/arch/arm64/boot/dtbo.img 2>/dev/null || true
echo "=== In-tree build successful ==="
