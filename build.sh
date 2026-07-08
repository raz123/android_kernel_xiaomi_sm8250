#!/usr/bin/env bash
set -e

# ── Architecture ───────────────────────────────────────────────────────────────
export ARCH=arm64
export SUBARCH=arm64

# ── Compiler flags ─────────────────────────────────────────────────────────────
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip

# ── Config & Output ────────────────────────────────────────────────────────────
DEFCONFIG=vendor/xiaomi/alioth_defconfig
OUT_DIR=out

# ── Build ──────────────────────────────────────────────────────────────────────
echo "[1/3] Applying defconfig..."
make -j$(nproc) O=$OUT_DIR $DEFCONFIG

echo "[1.5/3] Silent resolve new config symbols..."
yes "1" 2>/dev/null | make -j$(nproc) O=$OUT_DIR oldconfig 2>&1 || true

echo "[2/3] Compiling kernel..."
yes "1" 2>/dev/null | make -j$(nproc) O=$OUT_DIR CC=clang LLVM=1 LLVM_IAS=1

echo "[3/3] Done! Artifacts in $OUT_DIR/arch/arm64/boot/"
ls -lh $OUT_DIR/arch/arm64/boot/Image* $OUT_DIR/arch/arm64/boot/dtbo.img 2>/dev/null || true
