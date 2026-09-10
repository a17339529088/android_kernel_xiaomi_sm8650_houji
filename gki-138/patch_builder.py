# Mute SUSFS log; 6.1.138 GKI -Werror vs newer susfs maps hide.
from pathlib import Path
import argparse


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--scripts", required=True)
    args = p.parse_args()
    d = Path(args.scripts)
    kb = d / "kernel_builder.py"
    txt = kb.read_text(encoding="utf-8")
    if "CONFIG_KSU_SUSFS_ENABLE_LOG=y" not in txt:
        raise SystemExit("ENABLE_LOG line missing")
    txt = txt.replace("CONFIG_KSU_SUSFS_ENABLE_LOG=y", "CONFIG_KSU_SUSFS_ENABLE_LOG=n")
    old = '''        if "struct dentry *dentry;" in content:
            content = content.replace("struct dentry *dentry;", "struct dentry *dentry = NULL;")
            logger.info("已修复 dentry 未初始化问题")
'''
    new = '''        if "struct dentry *dentry;" in content:
            content = content.replace("struct dentry *dentry;", "struct dentry *dentry __maybe_unused = NULL;")
            logger.info("dentry marked __maybe_unused")
        if "bypass:" in content:
            import re as _re
            content = _re.sub(r"^(\\s*)bypass:\\s*$", r"\\1; /* bypass */", content, flags=_re.M)
            logger.info("removed unused label bypass")
        if "show_vma_header_prefix_fake" in content:
            content = content.replace(
                "static void show_vma_header_prefix_fake",
                "static void __maybe_unused show_vma_header_prefix_fake",
            )
            logger.info("marked show_vma_header_prefix_fake unused")
        proc_mk = Path("fs/proc/Makefile")
        if proc_mk.exists():
            mk = proc_mk.read_text(encoding="utf-8", errors="replace")
            flag = "CFLAGS_task_mmu.o += -Wno-unused-function -Wno-unused-variable -Wno-unused-label\\n"
            if "CFLAGS_task_mmu.o" not in mk:
                proc_mk.write_text(mk + "\\n" + flag, encoding="utf-8")
                logger.info("added CFLAGS_task_mmu.o unused-warn disable")
'''
    if old not in txt:
        raise SystemExit("task_mmu dentry block not found")
    txt = txt.replace(old, new, 1)
    kb.write_text(txt, encoding="utf-8")
    print("patched ENABLE_LOG=n + task_mmu unused-function/Makefile")


if __name__ == "__main__":
    main()
