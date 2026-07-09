#!/bin/bash
set -euo pipefail

DEVICE="${DEVICE:-alioth}"
KSU="${KSU:-1}"
TOOLCHAIN_PATH="/opt/zyc-clang/bin"

# Verify toolchain
if [ ! -d "$TOOLCHAIN_PATH" ]; then
    echo "ERROR: ZyC-Clang not found at $TOOLCHAIN_PATH"
    exit 1
fi
export PATH="$TOOLCHAIN_PATH:$PATH"
echo "Using: $(clang --version | head -1)"

# Verify cross-compiler
if ! command -v aarch64-linux-gnu-ld >/dev/null 2>&1; then
    echo "ERROR: aarch64-linux-gnu-ld not found"
    exit 1
fi

MAKE_ARGS="ARCH=arm64 \
           SUBARCH=arm64 \
           O=out \
           HOSTCC=clang \
           CLANG_TRIPLE=aarch64-linux-gnu- \
           CROSS_COMPILE=aarch64-linux-gnu- \
           CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
           CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
           LLVM=1 \
           LLVM_IAS=1"

# Clean previous build
if [ "${CLEAN_BUILD:-0}" = "1" ] || [ ! -f "out/Makefile" ]; then
    rm -rf out/
fi

echo "== Generate config"
# jun09 uses vendor/xiaomi/ path for defconfig
make $MAKE_ARGS vendor/xiaomi/${DEVICE}_defconfig

# Merge vendor overlays (jun09 requires sm8250-common + alioth configs)
if [ -f "arch/arm64/configs/vendor/xiaomi/sm8250-common.config" ] && \
   [ -f "arch/arm64/configs/vendor/xiaomi/alioth.config" ]; then
    scripts/kconfig/merge_config.sh -m out/.config \
        arch/arm64/configs/vendor/xiaomi/sm8250-common.config \
        arch/arm64/configs/vendor/xiaomi/alioth.config
fi

# Apply additional configs
scripts/config --file out/.config --disable IKHEADERS
if [ "$KSU" = "1" ]; then
    scripts/config --file out/.config -e CONFIG_KSU
    scripts/config --file out/.config -e CONFIG_KSU_MANUAL_HOOK
fi
if [ -n "${KBUILD_BUILD_VERSION:-}" ]; then
    scripts/config --file out/.config --set-str LOCALVERSION "-rv-b${KBUILD_BUILD_VERSION}"
fi

# Resolve dependency chain after config changes
make $MAKE_ARGS olddefconfig

# Remove .git so prepare3's git-status check is skipped entirely
rm -rf .git 2>/dev/null || true

# Kernel 4.19 compat: MODULE_IMPORT_NS not defined until 5.x+
if ! grep -q "MODULE_IMPORT_NS" include/linux/module.h 2>/dev/null; then
    echo "" >> include/linux/module.h
    echo "#ifndef MODULE_IMPORT_NS" >> include/linux/module.h
    echo "#define MODULE_IMPORT_NS(_ns)" >> include/linux/module.h
    echo "#endif" >> include/linux/module.h
    echo "Added MODULE_IMPORT_NS compat shim"
fi

echo "Building kernel..."
make $MAKE_ARGS CC="ccache clang" V=1 -j${PARALLEL_JOBS:-$(nproc)}
echo ""

# Generate combined DTB
echo "Generating out/arch/arm64/boot/dtb......"
find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb

# Collect output
mkdir -p out/modules
if [ -f "out/arch/arm64/boot/Image" ]; then
    gzip -f out/arch/arm64/boot/Image
fi
if [ -f "out/arch/arm64/boot/dtb" ]; then
    gzip -f out/arch/arm64/boot/dtb
fi

find out/ -name "*.ko" -exec cp {} out/modules/ \; 2>/dev/null || true
[ -f "vm_tuning.sh" ] && cp vm_tuning.sh out/modules/

echo "=== ccache stats ==="
ccache -s 2>/dev/null | grep -E 'Hits:|Misses:|Cache size' || echo "ccache stats unavailable"
echo "===================="

echo "=== Build complete ==="
ls -la out/arch/arm64/boot/Image.gz out/arch/arm64/boot/dtbo.img 2>/dev/null || true
