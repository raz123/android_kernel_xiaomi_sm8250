#!/bin/bash
set -euxo pipefail

DEVICE="${DEVICE:-alioth}"
KSU="${KSU:-1}"
TOOLCHAIN_PATH="/opt/zyc-clang/bin"

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
    scripts/config --enable CONFIG_KSU
    scripts/config --enable CONFIG_KSU_MANUAL_MODE
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

# Pre-generate linker scripts (pattern rule fails in Docker CI)
echo "== Pre-generating linker scripts ==="
echo "Checking vdso.lds.S: $(ls -la arch/arm64/kernel/vdso/vdso.lds.S 2>&1)"
echo "Checking vdso.lds: $(ls -la arch/arm64/kernel/vdso/vdso.lds 2>&1)"
clang -E -P -Uaarch64 -D__ASSEMBLY__ -DLINKER_SCRIPT \
    -I./arch/arm64/include -I./include -include ./include/linux/kconfig.h \
    arch/arm64/kernel/vdso/vdso.lds.S \
    -o arch/arm64/kernel/vdso/vdso.lds && \
echo "Pre-generated vdso.lds successfully" || echo "Pre-generation failed"
echo "Post-check: $(ls -la arch/arm64/kernel/vdso/vdso.lds 2>&1)"

echo "Building kernel (in-tree)..."
make $MAKE_ARGS CC="ccache clang" V=1 -j1
echo ""

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
