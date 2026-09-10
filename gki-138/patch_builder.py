# Mute SUSFS log + fix 6.1.138 task_mmu Werror after susfs patch.
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
    old = '''                self._run_cmd(f"patch -p1 --fuzz=3 < {patch_file}", check=False)
                self._chdir(self.work_dir)
'''
    new = '''                self._run_cmd(f"patch -p1 --fuzz=3 < {patch_file}", check=False)
                # 6.1.138 GKI -Werror: susfs maps hide can leave unused dentry/bypass
                self._run_cmd(
                    "sed -i 's/struct dentry \\*dentry;/struct dentry *dentry __maybe_unused;/' fs/proc/task_mmu.c",
                    check=False,
                )
                self._run_cmd(
                    "sed -i 's/^[[:space:]]*bypass:/\t; \\/* bypass *\\//' fs/proc/task_mmu.c",
                    check=False,
                )
                self._chdir(self.work_dir)
'''
    if old not in txt:
        raise SystemExit("apply_susfs patch block not found")
    txt = txt.replace(old, new, 1)
    kb.write_text(txt, encoding="utf-8")
    print("patched ENABLE_LOG=n + task_mmu Werror fixup")


if __name__ == "__main__":
    main()
