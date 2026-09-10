# Patch ShirkNeko GKI builder: ReSukiSU fc804b6 + hide log + empty localversion.
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCRIPTS = ROOT  # overwritten by --scripts


def main() -> None:
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("--scripts", required=True)
    args = p.parse_args()
    d = Path(args.scripts)
    kb = (d / "kernel_builder.py").read_text(encoding="utf-8")
    old = '''    def add_kernelsu(self):
        logger.info("=== 添加 KernelSU ===")
        self._chdir(self.work_dir)
        setup_url = (f"https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/{self.config.kernelsu_commit}/kernel/setup.sh"
                    if self.config.kernelsu_commit else KSU_REPO_CONFIG["setup_script"])
        self._run_cmd(f"curl -LSs {setup_url} | bash -s builtin", check=False)
        if self.config.kernelsu_commit:
            ksu_dir = self.work_dir / "KernelSU"
            if ksu_dir.exists():
                self._chdir(ksu_dir)
                self._run_cmd(f"git checkout {self.config.kernelsu_commit}", check=False)
                self._chdir(self.work_dir)
'''
    new = '''    def add_kernelsu(self):
        logger.info("=== 添加 ReSukiSU fc804b6 ===")
        self._chdir(self.work_dir)
        ksu_dir = self.work_dir / "KernelSU"
        if not ksu_dir.exists():
            self._run_cmd("git clone https://github.com/hushangda/ReSukiSU.git KernelSU", check=False)
        self._chdir(ksu_dir)
        self._run_cmd("git fetch --all", check=False)
        self._run_cmd("git checkout fc804b6bc7b18f389dfa3c5a05cb3063aac97db0", check=False)
        self._chdir(self.work_dir)
        driver = self.work_dir / "common/drivers"
        if not driver.exists():
            driver = self.work_dir / "drivers"
        self._run_cmd(f"ln -sfn $(realpath --relative-to={driver} {ksu_dir}/kernel) {driver}/kernelsu", check=False)
        mk = driver / "Makefile"
        kf = driver / "Kconfig"
        if mk.exists() and "kernelsu" not in mk.read_text(encoding="utf-8", errors="replace"):
            with mk.open("a", encoding="utf-8") as f:
                f.write("\\nobj-$(CONFIG_KSU) += kernelsu/\\n")
        if kf.exists() and "drivers/kernelsu/Kconfig" not in kf.read_text(encoding="utf-8", errors="replace"):
            txt = kf.read_text(encoding="utf-8", errors="replace")
            kf.write_text(txt.replace("endmenu", 'source "drivers/kernelsu/Kconfig"\\nendmenu', 1), encoding="utf-8")
'''
    if old not in kb:
        raise SystemExit("add_kernelsu block not found")
    kb = kb.replace(old, new)
    kb = kb.replace("CONFIG_KSU_SUSFS_ENABLE_LOG=y", "CONFIG_KSU_SUSFS_ENABLE_LOG=n")
    (d / "kernel_builder.py").write_text(kb, encoding="utf-8")
    print("patched kernel_builder.py")


if __name__ == "__main__":
    main()
