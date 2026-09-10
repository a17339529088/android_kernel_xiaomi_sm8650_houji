# Xiaomi 14 (houji) ReSukiSU

Device: Xiaomi 14 / 小米14 (`houji`, SM8650 pineapple)

**实机（2026-09-10）** `23127PN0CC` Android 16：
`uname -r` = `6.1.138-android14-11-g0c3d559bcd85-ab14529422`
GKI 枝 = `android14-6.1-2025-06`（SUBLEVEL 138）。**禁刷下面 6.1.25 OSS Image。**

## Tags

| tag | 用途 |
|---|---|
| `houji-mi14-6.1.138` | **这台机用这个**：GKI 6.1.138 + ReSukiSU `fc804b6` + susfs |
| `houji-mi14-6.1.25-hide2` | OSS shennong-u-oss，**对不上这台 6.1.138** |
| `houji-mi14-6.1.25-hide1` / `houji-mi14-6.1.25` | 冻结，勿刷 |

| phone | repo | tag | kernel |
|---|---|---|---|
| 小米11 venus SM8350 | `android_kernel_xiaomi_sm8350_venus` | `venus-mi11-5.4.302` | 5.4.302 |
| 小米14 houji SM8650 | `android_kernel_xiaomi_sm8650_houji` | `houji-mi14-6.1.138` | GKI 6.1.138 |

## Build（6.1.138 GKI）

Actions: **Build Houji GKI 6.1.138** → Run workflow。
脚本：`gki-138/`。

## Flash

1. `ro.product.device=houji`
2. 先保存官方 `uname -r`（必须是 `6.1.138-android14-11-...`）给 SUSFS spoof
3. magiskboot 换 stock boot 的 kernel，或刷 AnyKernel3
4. `fastboot boot` 先试，再 `flash boot`

## OSS 6.1.25（不要给这台用）

```bash
git checkout houji-mi14-6.1.25-hide2
./build_houji.sh
```
