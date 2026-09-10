#!/usr/bin/env bash
# Xiaomi 14 (houji / SM8650 pineapple) kernel build with ReSukiSU.
# Pattern copied from android_kernel_xiaomi_sm8350_venus/build_venus.sh.
# Base: shennong-u-oss 6.1.25 (MiCode: Xiaomi 14 AND 14 Pro Android U).
#
# HIDE=1 (default): strip KSU from /proc/config.gz, mute SUSFS klog,
# drop KernelSU/SukiSU literals, do not stamp custom LOCALVERSION.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPM="${KPM:-1}"
HIDE="${HIDE:-1}"
if [[ "$KPM" =~ ^(1|y|Y|yes|YES|true|TRUE|on|ON)$ ]]; then
  KPM=1
elif [[ "$KPM" =~ ^(0|n|N|no|NO|false|FALSE|off|OFF)$ ]]; then
  KPM=0
else
  echo "ERROR: KPM must be 1 or 0" >&2
  exit 1
fi
if [[ "$HIDE" =~ ^(1|y|Y|yes|YES|true|TRUE|on|ON)$ ]]; then
  HIDE=1
elif [[ "$HIDE" =~ ^(0|n|N|no|NO|false|FALSE|off|OFF)$ ]]; then
  HIDE=0
else
  echo "ERROR: HIDE must be 1 or 0" >&2
  exit 1
fi
JOBS="${JOBS:-$(nproc)}"
if (( KPM )); then
  DEFAULT_OUT_DIR="$ROOT_DIR/out-houji-6.1.25-kpm"
else
  DEFAULT_OUT_DIR="$ROOT_DIR/out-houji-6.1.25"
fi
OUT_DIR="${OUT_DIR:-$DEFAULT_OUT_DIR}"

export ARCH=arm64
export SUBARCH=arm64
export LLVM=1
export LLVM_IAS=1
export CC=clang
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip
export READELF=llvm-readelf
unset KSU_MANAGER_PACKAGE

MAKE_ARGS=(
  O="$OUT_DIR"
  ARCH="$ARCH"
  SUBARCH="$SUBARCH"
  LLVM="$LLVM"
  LLVM_IAS="$LLVM_IAS"
  CC="$CC"
  LD="$LD"
  AR="$AR"
  NM="$NM"
  OBJCOPY="$OBJCOPY"
  OBJDUMP="$OBJDUMP"
  STRIP="$STRIP"
  READELF="$READELF"
)

cd "$ROOT_DIR"
mkdir -p "$OUT_DIR"

if [[ ! -d "$ROOT_DIR/KernelSU/kernel" ]]; then
  echo "ERROR: KernelSU submodule missing. Run: git submodule update --init --recursive" >&2
  exit 1
fi
if [[ ! -e "$ROOT_DIR/drivers/kernelsu" ]]; then
  ln -sfn ../KernelSU/kernel "$ROOT_DIR/drivers/kernelsu"
fi

hide_ksu_literals() {
  # Working-tree only. Do not commit. Drops the strings Momo/Native Test strings on Image.
  local kdir="$ROOT_DIR/KernelSU/kernel"
  [[ -f "$kdir/include/klog.h" ]] || return 0
  sed -i 's/#define pr_fmt(fmt) "KernelSU: " fmt/#define pr_fmt(fmt) fmt/' "$kdir/include/klog.h"
  find "$kdir" -type f \( -name '*.c' -o -name '*.h' \) -print0 | xargs -0 sed -i \
    -e 's/MODULE_DESCRIPTION("Android KernelSU")/MODULE_DESCRIPTION("Android")/' \
    -e 's/You are running KernelSU in DEBUG mode/debug mode/' \
    -e 's/KernelSU will abort initialization/init abort/' \
    -e 's/Initialized on: %s (%s) with driver version/init %s %s ver/'
}

echo "=== gki_defconfig + pineapple_GKI fragment ==="
make "${MAKE_ARGS[@]}" gki_defconfig
PINEAPPLE_FRAG="$ROOT_DIR/arch/arm64/configs/vendor/pineapple_GKI.config"
if [[ -f "$PINEAPPLE_FRAG" ]]; then
  if [[ -x "$ROOT_DIR/scripts/kconfig/merge_config.sh" ]]; then
    ARCH=arm64 "$ROOT_DIR/scripts/kconfig/merge_config.sh" -m -O "$OUT_DIR" \
      "$OUT_DIR/.config" "$PINEAPPLE_FRAG"
  else
    echo "WARN: merge_config.sh missing, concatenating pineapple fragment" >&2
    cat "$PINEAPPLE_FRAG" >> "$OUT_DIR/.config"
  fi
else
  echo "WARN: $PINEAPPLE_FRAG not found" >&2
fi

# Do not stamp a custom LOCALVERSION. Stock gki_defconfig has none.
# A "-sukisu"/"-XiaoYang" suffix is an immediate uname -r detect.
"$ROOT_DIR/scripts/config" --file "$OUT_DIR/.config" \
  --disable LOCALVERSION_AUTO \
  --set-str LOCALVERSION ""

CONFIG_ARGS=(
  --enable ZRAM
  --enable CRYPTO_LZ4
  --enable ZRAM_DEF_COMP_LZ4
  --disable ZRAM_DEF_COMP_LZORLE
  --disable ZRAM_DEF_COMP_LZO
  --disable ZRAM_DEF_COMP_ZSTD
  --disable ZRAM_DEF_COMP_LZ4HC
  --disable ZRAM_DEF_COMP_842
  --enable F2FS_FS_COMPRESSION
  --enable F2FS_FS_LZO
  --enable F2FS_FS_LZORLE
  --enable F2FS_FS_LZ4
  --enable F2FS_FS_LZ4HC
  --enable F2FS_FS_ZSTD
  --enable KSU
  --disable KSU_DEBUG
  --disable KSU_TOOLKIT_SUPPORT
  --set-str KSU_FULL_NAME_FORMAT "%KSU_VERSION%"
  --enable KSU_MULTI_MANAGER_SUPPORT
  --enable KSU_DISABLE_IN_RECOVERY
  --disable KSU_TRACEPOINT_HOOK
  --disable KSU_MANUAL_HOOK
  --enable KSU_SUSFS
  --enable KSU_SUSFS_SUS_PATH
  --enable KSU_SUSFS_SUS_MOUNT
  --enable KSU_SUSFS_SUS_KSTAT
  --enable KSU_SUSFS_SPOOF_UNAME
  --enable KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS
  --enable KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG
  --enable KSU_SUSFS_OPEN_REDIRECT
  --enable KSU_SUSFS_SUS_MAP
  --enable KALLSYMS
  --enable KALLSYMS_ALL
  --enable BPF_STREAM_PARSER
  --enable KPROBES
  --enable MODULES
  --enable IKCONFIG
  --enable IKCONFIG_PROC
)

if (( HIDE )); then
  CONFIG_ARGS+=(--disable KSU_SUSFS_ENABLE_LOG)
else
  CONFIG_ARGS+=(--enable KSU_SUSFS_ENABLE_LOG)
fi

if grep -q 'F2FS_UNFAIR_RWSEM' "$ROOT_DIR/fs/f2fs/Kconfig" 2>/dev/null; then
  CONFIG_ARGS+=(--enable F2FS_UNFAIR_RWSEM)
fi
if grep -q 'F2FS_CP_OPT' "$ROOT_DIR/fs/f2fs/Kconfig" 2>/dev/null; then
  CONFIG_ARGS+=(--enable F2FS_CP_OPT)
fi

if (( KPM )); then
  CONFIG_ARGS+=(--enable KPM)
else
  CONFIG_ARGS+=(--disable KPM)
fi

"$ROOT_DIR/scripts/config" --file "$OUT_DIR/.config" "${CONFIG_ARGS[@]}"
make "${MAKE_ARGS[@]}" olddefconfig

if (( HIDE )); then
  hide_ksu_literals
  # Keep /proc/config.gz (stock GKI has it) but strip KSU/KPM so detectors
  # grepping CONFIG_KSU=y get a stock-looking file.
  python3 - "$OUT_DIR/.config" "$OUT_DIR/.config.ikconfig" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
pat = re.compile(r"^CONFIG_(KSU|KPM)(_|=)")
with open(src, encoding="utf-8", errors="replace") as f:
    lines = f.readlines()
out = []
for line in lines:
    if pat.match(line):
        continue
    if line.startswith("# CONFIG_KSU") or line.startswith("# CONFIG_KPM"):
        continue
    out.append(line)
with open(dst, "w", encoding="utf-8", newline="\n") as f:
    f.writelines(out)
print("ikconfig sanitized", src, "->", dst, "dropped", len(lines) - len(out), "ksu/kpm lines")
PY
  MK="$ROOT_DIR/kernel/Makefile"
  if grep -q '$(obj)/config_data: $(KCONFIG_CONFIG) FORCE' "$MK"; then
    sed -i 's|$(obj)/config_data: $(KCONFIG_CONFIG) FORCE|$(obj)/config_data: $(objtree)/.config.ikconfig FORCE|' "$MK"
  fi
  grep -q 'config_data: $(objtree)/.config.ikconfig' "$MK" || {
    echo "ERROR: failed to retarget IKCONFIG to .config.ikconfig" >&2
    exit 1
  }
fi

if grep -q '^CONFIG_ZRAM=' "$OUT_DIR/.config"; then
  grep -q '^CONFIG_ZRAM_DEF_COMP="lz4"$' "$OUT_DIR/.config" || \
    echo "WARN: ZRAM default compressor is not lz4" >&2
fi

for required_config in \
  'CONFIG_KSU=y' \
  'CONFIG_KSU_MULTI_MANAGER_SUPPORT=y' \
  'CONFIG_KSU_DISABLE_IN_RECOVERY=y' \
  'CONFIG_KSU_SUSFS=y' \
  'CONFIG_KPROBES=y'; do
  grep -q "^$required_config$" "$OUT_DIR/.config" || {
    echo "ERROR: missing $required_config" >&2
    exit 1
  }
done
grep -q '^# CONFIG_KSU_DEBUG is not set$' "$OUT_DIR/.config" || \
  grep -q '^CONFIG_KSU_DEBUG=n$' "$OUT_DIR/.config" || {
    echo "ERROR: CONFIG_KSU_DEBUG must be off" >&2
    exit 1
  }
if (( HIDE )); then
  grep -q '^# CONFIG_KSU_SUSFS_ENABLE_LOG is not set$' "$OUT_DIR/.config" || {
    echo "ERROR: CONFIG_KSU_SUSFS_ENABLE_LOG must be off when HIDE=1" >&2
    exit 1
  }
fi
grep -q '^# CONFIG_KSU_TRACEPOINT_HOOK is not set$' "$OUT_DIR/.config" || {
  echo "ERROR: CONFIG_KSU_TRACEPOINT_HOOK must be disabled (same as venus ReSukiSU inline)" >&2
  exit 1
}
grep -q '^# CONFIG_KSU_MANUAL_HOOK is not set$' "$OUT_DIR/.config" || {
  echo "ERROR: CONFIG_KSU_MANUAL_HOOK must be disabled for ReSukiSU SuSFS inline mode" >&2
  exit 1
}
if (( KPM )); then
  grep -q '^CONFIG_KPM=y$' "$OUT_DIR/.config" || {
    echo "ERROR: CONFIG_KPM is not enabled" >&2
    exit 1
  }
fi

rm -f "$OUT_DIR/kernel/config_data" \
      "$OUT_DIR/kernel/config_data.gz" \
      "$OUT_DIR/kernel/configs.o" \
      "$OUT_DIR/kernel/.configs.o.cmd"
make -j"$JOBS" "${MAKE_ARGS[@]}" Image Image.gz dtbs

if grep -aq 'com\.resukisu\.resukisu' "$OUT_DIR/vmlinux"; then
  echo "ERROR: manager package restriction is still embedded in vmlinux" >&2
  exit 1
fi

if (( HIDE )); then
  FAIL=0
  for needle in 'KernelSU: ' 'XiaoYang' 'sukisu' 'SukiSU' 'ReSukiSU' 'CONFIG_KSU=y'; do
    if grep -aFq "$needle" "$OUT_DIR/vmlinux"; then
      echo "ERROR: hide leak in vmlinux: $needle" >&2
      FAIL=1
    fi
  done
  if grep -aFq 'CONFIG_KSU=y' "$OUT_DIR/kernel/config_data" 2>/dev/null; then
    echo "ERROR: IKCONFIG still contains CONFIG_KSU=y" >&2
    FAIL=1
  fi
  if (( FAIL )); then
    exit 1
  fi
  echo "hide: vmlinux string scan clean (KernelSU:/XiaoYang/sukisu/CONFIG_KSU=y)"
fi

KERNEL_IMAGE="$OUT_DIR/arch/arm64/boot/Image"
KERNEL_IMAGE_GZ="$OUT_DIR/arch/arm64/boot/Image.gz"
echo "HIDE: $([[ "$HIDE" == 1 ]] && echo on || echo off)"
echo "KSU manager package restriction: disabled"
echo "ReSukiSU multi-manager support: enabled"
echo "ReSukiSU + SuSFS: enabled"
echo "SUSFS klog: $([[ "$HIDE" == 1 ]] && echo disabled || echo enabled)"
echo "IKCONFIG: stock-looking (KSU/KPM stripped from /proc/config.gz)"
echo "LOCALVERSION: empty (no -sukisu stamp)"
echo "KPM: $([[ "$KPM" == 1 ]] && echo enabled || echo disabled)"
echo "Image: $KERNEL_IMAGE"
echo "Image.gz: $KERNEL_IMAGE_GZ"
echo "Next: magiskboot unpack stock boot.img -> replace kernel with Image -> repack"
echo "Match phone uname -r before flashing. This tree is 6.1.25 (Android U OSS)."
