#!/usr/bin/env bash
# Launch the SGLang OpenAI-compatible server for Ripple-65B-Preview + DFlash2
# (DFLASH speculative decoding, tool-call + reasoning parsers).
#
# Env overrides:
#   MODEL_DIR     (default models/target)
#   DRAFT_DIR     (default models/draft-4.55bpw)
#   DRAFT_QUANT   `exl3` (default) or `unquant` (BF16 draft)
#   CTX_LEN       (default 131072)
#   MEM_FRAC      (default 0.82)
#   PORT          (default 30000)
#   HOST          (default 127.0.0.1)
#   MAX_REQS      (default 8)
#   SGLANG_EXL3_MGEMM (default 1)
#   VENV_DIR      (default .venv)
#   PYTHON        (default $VENV_DIR/bin/python)
#   LOG           (default server.log)
#   PIDFILE       (default server.pid)
#   READY_TIMEOUT (default 900 seconds)
#   DRY_RUN=1     print the launch command without starting the server
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

VENV_DIR="${VENV_DIR:-.venv}"
DEPS_DIR="${DEPS_DIR:-.deps}"
MODEL_DIR="${MODEL_DIR:-models/target}"
DRAFT_DIR="${DRAFT_DIR:-models/draft-4.55bpw}"
DRAFT_QUANT="${DRAFT_QUANT:-exl3}"
CTX_LEN="${CTX_LEN:-131072}"
MEM_FRAC="${MEM_FRAC:-0.82}"
PORT="${PORT:-30000}"
HOST="${HOST:-127.0.0.1}"
MAX_REQS="${MAX_REQS:-8}"
SGLANG_EXL3_MGEMM="${SGLANG_EXL3_MGEMM:-1}"
PYTHON="${PYTHON:-$VENV_DIR/bin/python}"
LOG="${LOG:-server.log}"
PIDFILE="${PIDFILE:-server.pid}"
READY_TIMEOUT="${READY_TIMEOUT:-900}"

export SGLANG_EXL3_MGEMM
export MODEL_DIR DRAFT_DIR DRAFT_QUANT CTX_LEN MEM_FRAC PORT HOST MAX_REQS
export PYTHONPATH="$ROOT/$DEPS_DIR/sglang-exl3/src:$HERE:${PYTHONPATH:-}"
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
export PATH="$ROOT/$VENV_DIR/bin:$CUDA_HOME/bin:${PATH:-/usr/bin:/bin}"

if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] launch command:"
    echo "  $PYTHON scripts/serve_ripple.py"
    echo "[dry-run] env: MODEL_DIR=$MODEL_DIR DRAFT_DIR=$DRAFT_DIR DRAFT_QUANT=$DRAFT_QUANT"
    echo "           CTX_LEN=$CTX_LEN MEM_FRAC=$MEM_FRAC PORT=$PORT HOST=$HOST MAX_REQS=$MAX_REQS"
    echo "           SGLANG_EXL3_MGEMM=$SGLANG_EXL3_MGEMM"
    exit 0
fi

[ -x "$PYTHON" ] || { echo "missing $PYTHON — run bash scripts/setup.sh (or bash scripts/run.sh)"; exit 1; }
[ -d "$MODEL_DIR" ] || { echo "missing target pack at $MODEL_DIR — run bash scripts/download.sh (or bash scripts/run.sh)"; exit 1; }
[ -d "$DRAFT_DIR" ] || { echo "missing draft pack at $DRAFT_DIR — run bash scripts/download.sh (or bash scripts/run.sh)"; exit 1; }

setsid nohup "$PYTHON" scripts/serve_ripple.py "$@" >"$LOG" 2>&1 < /dev/null &
echo "$!" > "$PIDFILE"
echo "server pid=$(cat "$PIDFILE") log=$LOG (port $PORT; ready in ~60-180s)"

# Wait for readiness.
t0=$SECONDS
until curl -fsS "http://$HOST:$PORT/v1/models" >/dev/null 2>&1; do
    if ! kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "ERROR: server exited during startup; tail $LOG:"
        tail -40 "$LOG"
        exit 1
    fi
    if [ $((SECONDS - t0)) -gt "$READY_TIMEOUT" ]; then
        echo "ERROR: server not ready after ${READY_TIMEOUT}s; tail $LOG:"
        tail -40 "$LOG"
        exit 1
    fi
    sleep 5
done
echo "server ready: http://$HOST:$PORT/v1 (model id: ripple)"
echo "stop with: bash scripts/stop.sh"
