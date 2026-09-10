# houji GKI 6.1.138

实机 `23127PN0CC` uname：

`6.1.138-android14-11-g0c3d559bcd85-ab14529422`

对应 Google GKI 枝：`deprecated/android14-6.1-2025-06`（Makefile SUBLEVEL=138）。
manifest：`common-android14-6.1-2025-06`。

**禁止**把 `houji-mi14-6.1.25*` OSS Image 刷到这台机。

编：Actions → `Build Houji GKI 6.1.138` → Run workflow。

接线：ReSukiSU `fc804b6` + susfs4ksu `gki-android14-6.1`，HIDE：SUSFS log 关、不打 LOCALVERSION。

产物：`Image` / AnyKernel3。先 `fastboot boot`，起来再 `flash boot`。
