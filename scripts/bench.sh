#!/usr/bin/env bash
# Benchmark a running Ripple + DFlash2 server (see scripts/bench_decode.py).
#
# Usage:
#   bash scripts/bench.sh                # greedy + sampled (t=0.0 and 0.6)
#   GREEDY=1 bash scripts/bench.sh       # greedy only (AGENTS.md verification)
#
# Env overrides:
#   BASE_URL    (default http://127.0.0.1:30000)
#   MODEL_NAME  (default ripple)
#   MAX_TOKENS  (default 128)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ARGS=(--max-tokens "${MAX_TOKENS:-128}")
[ -n "${BASE_URL:-}" ] && ARGS+=(--base-url "$BASE_URL")
[ -n "${MODEL_NAME:-}" ] && ARGS+=(--model "$MODEL_NAME")
if [ "${GREEDY:-0}" = "1" ]; then
    ARGS+=(--greedy)
fi

exec "${PYTHON:-python3}" "$HERE/bench_decode.py" "${ARGS[@]}"
