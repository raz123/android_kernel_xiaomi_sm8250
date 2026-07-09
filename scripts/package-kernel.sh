#!/bin/bash
set -ex

cd "$(dirname "$0")/.."

# Run on HOST (not Docker) — only needs git, sed, python3
# Env: BUILD_NUMBER, KSU_ENABLED

# Determine KSU suffix for filename
KSU_SUFFIX="_ReSukiSU"
[ "${KSU_ENABLED}" != "true" ] && KSU_SUFFIX="_vanilla"

# Clone AnyKernel3 flasher (provides tools/ak3-core.sh, bin/, etc.)
rm -rf anykernel
git clone https://github.com/AstideLabs/AnyKernel3 -b master --single-branch --depth=1 anykernel

# Overlay our custom anykernel.sh
cp anykernel.sh anykernel/anykernel.sh

# === A/B SLOT FIX ===
grep -q '^SLOT_SELECT=' anykernel/anykernel.sh || sed -i '1i\SLOT_SELECT=active' anykernel/anykernel.sh

# Copy kernel image to root (AnyKernel3 looks for Image at root)
if [ -f out/arch/arm64/boot/Image.gz-dtb ]; then
  cp out/arch/arm64/boot/Image.gz-dtb anykernel/Image
elif [ -f out/arch/arm64/boot/Image.gz ]; then
  cp out/arch/arm64/boot/Image.gz anykernel/Image
elif [ -f out/arch/arm64/boot/Image ]; then
  cp out/arch/arm64/boot/Image anykernel/Image
fi

# Copy DTB to root
for dtb in out/arch/arm64/boot/dts/qcom/sm8250*.dtb out/arch/arm64/boot/dtb; do
  [ -f "$dtb" ] && cp "$dtb" anykernel/dtb && break
done

# Copy dtbo.img to root
[ -f out/arch/arm64/boot/dtbo.img ] && cp out/arch/arm64/boot/dtbo.img anykernel/dtbo.img

# Copy kernel modules
[ -d "out/modules" ] && [ "$(ls -A out/modules 2>/dev/null)" ] && mkdir -p anykernel/anykernel-modules/ && cp out/modules/*.ko anykernel/anykernel-modules/ 2>/dev/null || true

# Include VM Tuning script
[ -f "vm_tuning.sh" ] && cp vm_tuning.sh anykernel/anykernel-modules/ 2>/dev/null || true

# Build ZIP (use python zipfile — zip may not be installed)
ZIP_FILENAME="alioth-kernel_b${BUILD_NUMBER}${KSU_SUFFIX}.zip"
python3 -c "
import zipfile, os
with zipfile.ZipFile('$ZIP_FILENAME', 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
    for root, dirs, files in os.walk('anykernel'):
        dirs[:] = [d for d in dirs if d != '.git']
        for f in files:
            if f == '.gitignore': continue
            fp = os.path.join(root, f)
            arcname = os.path.relpath(fp, 'anykernel')
            zf.write(fp, arcname=arcname)
"
echo "=== Package complete: $ZIP_FILENAME ==="
