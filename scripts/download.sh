#!/usr/bin/env bash
# Download the Ripple-65B-Preview SAGE-REXL3 target pack and the EXL3 DFlash2
# draft pack from Hugging Face (with HF_XET_HIGH_PERFORMANCE=1).
#
# Target repositories on Hugging Face:
#   5.41bpw (default, 48GB+): vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw
#   2.57bpw (32GB-class):     vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw
#   1.95bpw (24GB-class):     vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw
#
# Draft repositories on Hugging Face:
#   EXL3 DFlash2 drafts:      vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3
#     subfolders: 4.55bpw (default), 3.60bpw, 3.08bpw (set DRAFT_SUBDIR=all for all 3)
#   BF16 DFlash2 draft:       ricursiveAI/Ripple-65B-Preview-DFlash2
#
# Env overrides:
#   QUANT        5.41bpw (default) | 2.57bpw | 1.95bpw
#   TARGET_REPO  override full HF repo ID for target
#   MODEL_DIR    local target directory (default models/target)
#   DRAFT_REPO   (default vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3)
#   DRAFT_SUBDIR 4.55bpw (default) | 3.60bpw | 3.08bpw | all | bf16
#   DRAFT_DIR    local draft directory (default models/draft-4.55bpw)
#   VENV_DIR     virtualenv directory (default .venv)
#   HF_TOKEN     optional Hugging Face token (otherwise uses ~/.cache/huggingface/token)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

VENV_DIR="${VENV_DIR:-.venv}"
PYTHON="${PYTHON:-$VENV_DIR/bin/python}"
if [ ! -x "$PYTHON" ]; then
    PYTHON="$(command -v python3)"
fi

QUANT="${QUANT:-5.41bpw}"
case "$QUANT" in
    5.41|5.41bpw) DEFAULT_TARGET_REPO="vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw" ;;
    2.57|2.57bpw) DEFAULT_TARGET_REPO="vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw" ;;
    1.95|1.95bpw) DEFAULT_TARGET_REPO="vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw" ;;
    *)            DEFAULT_TARGET_REPO="vcruz305/Ripple-65B-Preview-SAGE-REXL3-$QUANT" ;;
esac

TARGET_REPO="${TARGET_REPO:-$DEFAULT_TARGET_REPO}"
MODEL_DIR="${MODEL_DIR:-models/target}"
DRAFT_REPO="${DRAFT_REPO:-vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3}"
DRAFT_SUBDIR="${DRAFT_SUBDIR:-4.55bpw}"
DRAFT_DIR="${DRAFT_DIR:-models/draft-${DRAFT_SUBDIR}}"

export HF_XET_HIGH_PERFORMANCE=1
export TARGET_REPO MODEL_DIR DRAFT_REPO DRAFT_SUBDIR DRAFT_DIR

"$PYTHON" - <<'PY'
import os
import shutil
from pathlib import Path
from huggingface_hub import snapshot_download

target_repo = os.environ["TARGET_REPO"]
model_dir = Path(os.environ["MODEL_DIR"]).resolve()
draft_repo = os.environ["DRAFT_REPO"]
draft_subdir = os.environ["DRAFT_SUBDIR"]
draft_dir = Path(os.environ["DRAFT_DIR"]).resolve()

print(f"== Downloading target pack: {target_repo} -> {model_dir} ==", flush=True)
model_dir.mkdir(parents=True, exist_ok=True)
snapshot_download(
    repo_id=target_repo,
    local_dir=str(model_dir),
)

if draft_subdir.lower() == "bf16":
    bf16_repo = "ricursiveAI/Ripple-65B-Preview-DFlash2"
    print(f"== Downloading BF16 DFlash2 draft: {bf16_repo} -> {draft_dir} ==", flush=True)
    draft_dir.mkdir(parents=True, exist_ok=True)
    snapshot_download(repo_id=bf16_repo, local_dir=str(draft_dir))
elif draft_subdir.lower() == "all":
    base_draft_root = draft_dir.parent / "dflash2_q"
    print(f"== Downloading all EXL3 DFlash2 drafts ({draft_repo}) -> {base_draft_root} ==", flush=True)
    base_draft_root.mkdir(parents=True, exist_ok=True)
    snapshot_download(repo_id=draft_repo, local_dir=str(base_draft_root))
    for sub in ("4.55bpw", "3.60bpw", "3.08bpw"):
        src = base_draft_root / sub
        dst = draft_dir.parent / f"draft-{sub}"
        if src.is_dir() and not dst.exists():
            os.symlink(src, dst)
        print(f"  ready: {dst} -> {src}")
else:
    base_draft_root = draft_dir.parent / "dflash2_q"
    print(f"== Downloading EXL3 DFlash2 draft: {draft_repo} ({draft_subdir}) -> {draft_dir} ==", flush=True)
    base_draft_root.mkdir(parents=True, exist_ok=True)
    snapshot_download(
        repo_id=draft_repo,
        allow_patterns=[f"{draft_subdir}/*"],
        local_dir=str(base_draft_root),
    )
    sub_path = base_draft_root / draft_subdir
    if draft_dir != sub_path:
        if draft_dir.is_symlink() or draft_dir.is_file():
            draft_dir.unlink()
        elif draft_dir.is_dir() and not any(draft_dir.iterdir()):
            draft_dir.rmdir()
        if not draft_dir.exists():
            os.symlink(sub_path, draft_dir)
        else:
            for item in sub_path.iterdir():
                dest_item = draft_dir / item.name
                if not dest_item.exists():
                    shutil.copy2(item, dest_item)

print("== Download complete ==")
print(f"  MODEL_DIR={model_dir}")
print(f"  DRAFT_DIR={draft_dir}")
PY
