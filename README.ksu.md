# Xiaomi 14 (houji) ReSukiSU

Device: Xiaomi 14 / 小米14 (codename `houji`, SM8650 pineapple)
Kernel: 6.1.25 (`shennong-u-oss`, MiCode: Xiaomi 14 AND Xiaomi 14 Pro Android U)
Root: hushangda/ReSukiSU @ fc804b6 (same pin as venus)

Tag: `houji-mi14-6.1.25`

Xiaomi 11 freeze lives in a **different** repo/tag, do not mix trees:

| phone | repo | tag | kernel |
|---|---|---|---|
| 小米11 venus SM8350 | `android_kernel_xiaomi_sm8350_venus` | `venus-mi11-5.4.302` | 5.4.302 |
| 小米14 houji SM8650 | `android_kernel_xiaomi_sm8650_houji` | `houji-mi14-6.1.25` | 6.1.25 |

SM8350 5.4 cannot boot SM8650. This tree is the houji counterpart of the venus ReSukiSU integration (submodule + `drivers/kernelsu` symlink + Kconfig/Makefile hook + `build_*.sh` + Actions).

## Build

```bash
git checkout houji-mi14-ksu
git submodule update --init --recursive
# clang 17+ on PATH (6.1; not the venus r416183b)
./build_houji.sh
```

CI: `.github/workflows/build-houji-ksu.yml` (workflow_dispatch).

## Flash (own phone, bootloader unlocked)

1. `adb shell getprop ro.product.device` must be `houji` (14 Pro is `shennong`, same kernel family).
2. `adb shell uname -r` should start with `6.1.25`. If the phone is a newer HyperOS sublevel, rebase this tree first — mismatched KMI = modules fail / bootloop.
3. Unpack stock `boot.img` with magiskboot, replace `kernel` with `out-houji-6.1.25-kpm/arch/arm64/boot/Image`, repack.
4. `fastboot boot new-boot.img` first. Only `fastboot flash boot` after it boots.
5. Install a SukiSU/ReSukiSU manager APK (multi-manager, no package pin).

Do not flash a venus Image onto houji.
