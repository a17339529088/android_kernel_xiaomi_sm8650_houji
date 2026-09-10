# Xiaomi 14 (houji) ReSukiSU

Device: Xiaomi 14 / 小米14 (codename `houji`, SM8650 pineapple)
Kernel: 6.1.25 (`shennong-u-oss`, MiCode: Xiaomi 14 AND Xiaomi 14 Pro Android U)
Root: hushangda/ReSukiSU @ fc804b6 (same pin as venus)

Tags:
- `houji-mi14-6.1.25` — first wire-up
- `houji-mi14-6.1.25-hide1` — hide pass (default `HIDE=1`)

Xiaomi 11 freeze lives in a **different** repo/tag, do not mix trees:

| phone | repo | tag | kernel |
|---|---|---|---|
| 小米11 venus SM8350 | `android_kernel_xiaomi_sm8350_venus` | `venus-mi11-5.4.302` | 5.4.302 |
| 小米14 houji SM8650 | `android_kernel_xiaomi_sm8650_houji` | `houji-mi14-6.1.25-hide1` | 6.1.25 |

## Hide (kernel, HIDE=1 default)

- SuSFS: path/mount/kstat/map + spoof uname/cmdline + hide kallsyms
- SUSFS klog off (no `SUSFS:` in dmesg)
- `CONFIG_KSU_DEBUG` off
- `/proc/config.gz` still exists (stock GKI) but `CONFIG_KSU*` / `CONFIG_KPM*` stripped
- `uname` LOCALVERSION empty — **not** `-XiaoYang-houji-sukisu`
- compile-time literals `KernelSU:` / `SukiSU` / `XiaoYang` stripped; Image scan fails the build if they remain
- `HIDE=0 ./build_houji.sh` if you need klog for debug

This is kernel-side only. Apps still see userspace if you leave su/modules mounted.

## Userspace (after first boot)

1. Manager: enable **umount modules** for all non-root apps (default on SukiSU).
2. Install **SUSFS userspace module** (`susfs4ksu` / manager SUSFS page). Spoof uname to the phone's stock `uname -r` (read it **before** flashing).
3. Hide the manager APK (Hide My Applist / manager's own hide). Do not keep a visible `su` in PATH for untrusted apps.
4. Do not enable KSU debug or SUSFS log on a daily image.

## Build

```bash
git checkout houji-mi14-ksu
git submodule update --init --recursive
# clang 17+ on PATH (6.1; not the venus r416183b)
./build_houji.sh          # HIDE=1
# HIDE=0 ./build_houji.sh  # debug klog
```

CI: `.github/workflows/build-houji-ksu.yml` (workflow_dispatch).

## Flash (own phone, bootloader unlocked)

1. `adb shell getprop ro.product.device` must be `houji` (14 Pro is `shennong`, same kernel family).
2. Save stock `uname -r` first. It should start with `6.1.25`. Newer HyperOS sublevel → rebase, do not flash.
3. Unpack stock `boot.img` with magiskboot, replace `kernel` with `out-houji-6.1.25-kpm/arch/arm64/boot/Image`, repack.
4. `fastboot boot new-boot.img` first. Only `fastboot flash boot` after it boots.
5. Install a SukiSU/ReSukiSU manager APK (multi-manager, no package pin).

Do not flash a venus Image onto houji.
