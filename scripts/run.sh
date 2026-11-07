#!/usr/bin/env bash
# All-in-one launcher: installs SGLang 0.5.19 + vcruz305/sglang-exl3 + ExLlamaV3,
# downloads the Ripple-65B-Preview EXL3 target pack + 4.55bpw EXL3 DFlash2 draft,
# and starts the OpenAI-compatible server on http://127.0.0.1:30000/v1.
#
# Usage:
#   bash scripts/run.sh                          # 5.41bpw target + 4.55bpw DFlash2 draft
#   QUANT=2.57bpw bash scripts/run.sh            # 2.57bpw target + 4.55bpw DFlash2 draft
#   QUANT=1.95bpw bash scripts/run.sh            # 1.95bpw target + 4.55bpw DFlash2 draft
#   RUN_BENCH=1 GREEDY=1 bash scripts/run.sh     # also run the verification benchmark once ready
#
# Key repositories downloaded automatically:
#   SGLang EXL3 plugin: https://github.com/vcruz305/sglang-exl3
#   ExLlamaV3 kernels:  https://github.com/turboderp-org/exllamav3
#   Target 5.41bpw:     https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw
#   Target 2.57bpw:     https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw
#   Target 1.95bpw:     https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw
#   DFlash2 drafts:     https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

echo "=== [1/3] Setting up SGLang 0.5.19 + vcruz305/sglang-exl3 + ExLlamaV3 ==="
bash "$HERE/setup.sh"

echo "=== [2/3] Downloading Ripple-65B-Preview target & DFlash2 draft packs ==="
bash "$HERE/download.sh"

echo "=== [3/3] Starting SGLang + sglang-exl3 server ==="
bash "$HERE/serve.sh"

if [ "${RUN_BENCH:-0}" = "1" ]; then
    echo "=== Running benchmark verification ==="
    bash "$HERE/bench.sh"
fi
