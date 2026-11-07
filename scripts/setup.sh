#!/usr/bin/env bash
# Idempotent environment setup for serving Ripple-65B-Preview + DFlash2 on
# SGLang 0.5.19 with the vcruz305/sglang-exl3 plugin and ExLlamaV3 built from source.
#
# Plugin repository: https://github.com/vcruz305/sglang-exl3
#
# Usage:
#   bash scripts/setup.sh            # full install (idempotent)
#   bash scripts/setup.sh --check    # verify an existing environment (offline)
#
# Env overrides:
#   PYTHON               base interpreter (default python3)
#   VENV_DIR             virtualenv path (default .venv)
#   SGLANG_VERSION       SGLang version (default 0.5.19)
#   PLUGIN_REPO          sglang-exl3 repo (default https://github.com/vcruz305/sglang-exl3.git)
#   PLUGIN_REF           sglang-exl3 git ref/branch/commit (default master)
#   EXLLAMA_V3_REPO      ExLlamaV3 repo (default https://github.com/turboderp-org/exllamav3.git)
#   EXLLAMA_V3_REF       ExLlamaV3 git ref (default master)
#   DEPS_DIR             dependency checkouts (default .deps)
#   TORCH_CUDA_ARCH_LIST CUDA arch (auto-detected from GPU if unset; fallback 12.0)
#   TORCH_INDEX_URL      PyTorch wheel index (default https://download.pytorch.org/whl/cu130)
#   TORCH_VERSION        PyTorch version (default 2.13.0)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

PYTHON="${PYTHON:-python3}"
VENV_DIR="${VENV_DIR:-.venv}"
SGLANG_VERSION="${SGLANG_VERSION:-0.5.19}"
DEPS_DIR="${DEPS_DIR:-.deps}"
PLUGIN_REPO="${PLUGIN_REPO:-https://github.com/vcruz305/sglang-exl3.git}"
PLUGIN_REF="${PLUGIN_REF:-master}"
EXLLAMA_V3_REPO="${EXLLAMA_V3_REPO:-https://github.com/turboderp-org/exllamav3.git}"
EXLLAMA_V3_REF="${EXLLAMA_V3_REF:-}"
TORCH_INDEX_URL="${TORCH_INDEX_URL:-https://download.pytorch.org/whl/cu130}"
TORCH_VERSION="${TORCH_VERSION:-2.13.0}"

check() {
    PATH="$ROOT/$VENV_DIR/bin:/usr/local/cuda/bin:${PATH:-/usr/bin:/bin}" \
    PYTHONPATH="$ROOT/$DEPS_DIR/sglang-exl3/src:${PYTHONPATH:-}" "$VENV_DIR/bin/python" - <<'PY'
import shutil
import sys

ninja_bin = shutil.which("ninja")
if not ninja_bin:
    print("ERROR: ninja not found on PATH")
    sys.exit(1)
print(f"ninja OK ({ninja_bin})")

try:
    import torch
except Exception as e:
    print("ERROR: torch import failed:", e)
    sys.exit(1)
print(f"torch {torch.__version__} cuda={torch.version.cuda}")

try:
    import exllamav3_ext
    for sym in ("exl3_gemm", "exl3_mgemm"):
        if not hasattr(exllamav3_ext, sym):
            raise AssertionError(f"missing exllamav3_ext.{sym}")
except Exception as e:
    print("ERROR: exllamav3_ext check failed:", e)
    sys.exit(1)
print("exllamav3_ext OK (exl3_gemm / exl3_mgemm present)")

try:
    import sglang
except Exception as e:
    print("ERROR: sglang import failed:", e)
    sys.exit(1)
if sglang.__version__ != "0.5.19":
    print(f"WARNING: sglang {sglang.__version__} (measured recipe uses 0.5.19)")
else:
    print("sglang 0.5.19 OK")

try:
    import sglang_exl3
    from sglang_exl3.models.ricursive import RicursiveForCausalLM
    from sglang_exl3.models.dflash_exl3 import DFlash2DraftModel
except Exception as e:
    print("ERROR: sglang_exl3 hook import failed:", e)
    sys.exit(1)
print(f"sglang_exl3 OK ({sglang_exl3.__file__})")
print("sglang_exl3 hooks OK (RicursiveForCausalLM / DFlash2DraftModel)")
PY
}

if [ "${1:-}" = "--check" ]; then
    [ -x "$VENV_DIR/bin/python" ] || { echo "missing $VENV_DIR — run bash scripts/setup.sh"; exit 1; }
    check
    exit 0
fi

if [ ! -x "$VENV_DIR/bin/python" ]; then
    echo "== creating virtualenv at $VENV_DIR =="
    "$PYTHON" -m venv "$VENV_DIR"
fi
PIP="$VENV_DIR/bin/pip"
"$PIP" install --upgrade pip setuptools wheel ninja packaging

echo "== installing torch $TORCH_VERSION (cu130) =="
"$PIP" install --index-url "$TORCH_INDEX_URL" "torch==$TORCH_VERSION" || \
    "$PIP" install "torch==$TORCH_VERSION"

echo "== installing sglang $SGLANG_VERSION + huggingface_hub[hf_xet] =="
"$PIP" install "sglang[all]==$SGLANG_VERSION" "huggingface_hub[hf_xet]" safetensors fastparquet rich

# Auto-detect TORCH_CUDA_ARCH_LIST from the active GPU if not explicitly set.
if [ -z "${TORCH_CUDA_ARCH_LIST:-}" ]; then
    TORCH_CUDA_ARCH_LIST="$("$VENV_DIR/bin/python" - <<'PY'
import torch
if torch.cuda.is_available():
    maj, min_ = torch.cuda.get_device_capability(0)
    arch = f"{maj}.{min_}a" if (maj == 12 and min_ == 1) else f"{maj}.{min_}"
    print(arch)
else:
    print("12.0")
PY
)"
fi
export TORCH_CUDA_ARCH_LIST

mkdir -p "$DEPS_DIR"
if [ ! -d "$DEPS_DIR/exllamav3/.git" ]; then
    echo "== cloning ExLlamaV3 ($EXLLAMA_V3_REPO) =="
    git clone --filter=blob:none "$EXLLAMA_V3_REPO" "$DEPS_DIR/exllamav3"
fi
if [ -n "$EXLLAMA_V3_REF" ]; then
    git -C "$DEPS_DIR/exllamav3" fetch origin "$EXLLAMA_V3_REF" && \
        git -C "$DEPS_DIR/exllamav3" checkout FETCH_HEAD
fi
echo "== building ExLlamaV3 from source (TORCH_CUDA_ARCH_LIST=$TORCH_CUDA_ARCH_LIST) =="
TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST" "$PIP" install --no-build-isolation -e "$DEPS_DIR/exllamav3"

if [ ! -d "$DEPS_DIR/sglang-exl3/.git" ]; then
    echo "== cloning sglang-exl3 plugin ($PLUGIN_REPO) =="
    git clone --filter=blob:none "$PLUGIN_REPO" "$DEPS_DIR/sglang-exl3"
else
    echo "== updating sglang-exl3 plugin ($PLUGIN_REPO) =="
    git -C "$DEPS_DIR/sglang-exl3" fetch origin "$PLUGIN_REF"
fi
if [ -n "$PLUGIN_REF" ]; then
    git -C "$DEPS_DIR/sglang-exl3" fetch origin "$PLUGIN_REF" && \
        git -C "$DEPS_DIR/sglang-exl3" checkout FETCH_HEAD
fi

echo "== registering sglang-exl3 plugin in $VENV_DIR =="
SITE_PACKAGES="$("$VENV_DIR/bin/python" -c 'import site; print(site.getsitepackages()[0])')"
echo "$ROOT/$DEPS_DIR/sglang-exl3/src" > "$SITE_PACKAGES/sglang_exl3.pth"

echo "== verifying environment =="
check
echo "setup complete. Next: bash scripts/download.sh (or run everything with: bash scripts/run.sh)"
