# Xiaomi 14 (houji) ReSukiSU

Device: Xiaomi 14 / 小米14 (`houji`, SM8650 pineapple)
Kernel: 6.1.25 (`shennong-u-oss`) + ReSukiSU `fc804b6` + susfs4ksu `gki-android14-6.1`

Tags:
- `houji-mi14-6.1.25` — first wire-up (no in-tree susfs, do not use)
- `houji-mi14-6.1.25-hide1` — kconfig hide only
- `houji-mi14-6.1.25-hide2` — **use this**: kernel-side susfs + kallsyms/uname/mount/maps hide

| phone | repo | tag | kernel |
|---|---|---|---|
| 小米11 venus SM8350 | `android_kernel_xiaomi_sm8350_venus` | `venus-mi11-5.4.302` | 5.4.302 |
| 小米14 houji SM8650 | `android_kernel_xiaomi_sm8650_houji` | `houji-mi14-6.1.25-hide2` | 6.1.25 |

## Hide2 (kernel)

In-tree simonpunk susfs (same generation as android14-6.1 GKI):
- hide ksu/susfs/sukisu/ksud symbols from `/proc/kallsyms`
- hide sus mounts from mountinfo
- spoof uname / cmdline / bootconfig
- hide sus path / kstat / maps / open_redirect
- SELinux avc / maps umount

Build-time:
- `/proc/config.gz` exists but `CONFIG_KSU*`/`CONFIG_KPM*` stripped
- SUSFS klog off, `CONFIG_KSU_DEBUG` off
- LOCALVERSION empty (no `-sukisu` uname)
- KernelSU/SukiSU/XiaoYang literals scrubbed; Image scan gates the build

Not renamed (userspace ABI, manager/ksud need them):
- `/data/adb/ksud`, `/data/adb/ksu/`, `/system/bin/su`
Those stay hidden from untrusted apps via sus_path + umount, not by renaming.

## Userspace after boot

1. Manager: umount modules for all non-root apps
2. SUSFS module (`ksu_module_susfs` from susfs4ksu). Spoof uname = stock `uname -r` saved **before** flash
3. Hide manager APK
4. Do not enable SUSFS log / KSU debug

## Build

```bash
git checkout houji-mi14-ksu
git submodule update --init --recursive
./build_houji.sh          # HIDE=1
```

## Flash

1. `ro.product.device=houji`
2. Save stock `uname -r` (must start `6.1.25`)
3. magiskboot: replace kernel in stock boot.img with `out-houji-6.1.25-kpm/arch/arm64/boot/Image`
4. `fastboot boot` first, then `flash boot`
