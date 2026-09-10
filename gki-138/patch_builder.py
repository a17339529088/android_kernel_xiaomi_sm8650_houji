# Mute SUSFS log; fix 6.1.138 task_mmu -Werror after ShirkNeko's own fixup.
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
'''
    if old not in txt:
        raise SystemExit("task_mmu dentry block not found")
    txt = txt.replace(old, new, 1)
    kb.write_text(txt, encoding="utf-8")
    print("patched ENABLE_LOG=n + task_mmu unused after sukisu hide patch")


if __name__ == "__main__":
    main()
