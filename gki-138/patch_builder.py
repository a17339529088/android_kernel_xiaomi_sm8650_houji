# Only hide SUSFS klog. Keep ShirkNeko's SukiSU-Ultra wiring so GKI 6.1.138 links.
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
    kb.write_text(txt, encoding="utf-8")
    print("patched ENABLE_LOG=n")


if __name__ == "__main__":
    main()
