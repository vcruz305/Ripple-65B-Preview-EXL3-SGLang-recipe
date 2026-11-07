#!/usr/bin/env bash
# Stop the SGLang server tree started by serve.sh. Kills only PIDs recorded
# in server.pid plus their descendants (no pkill), then frees $PORT.
#
# Env overrides: PORT (default 30000), PIDFILE (default server.pid)
set -euo pipefail

PORT="${PORT:-30000}"
PIDFILE="${PIDFILE:-server.pid}"

kids() { ps -eo pid=,ppid= | awk -v p="$1" '$2==p {print $1}'; }
collect() {
    local p=$1 c
    for c in $(kids "$p"); do collect "$c"; done
    echo "$p"
}

SRV="$(cat "$PIDFILE" 2>/dev/null || true)"
if [ -n "$SRV" ] && kill -0 "$SRV" 2>/dev/null; then
    echo "stopping server tree rooted at pid $SRV"
    mapfile -t ALL < <(collect "$SRV")
    # TERM children before parents, youngest first.
    for i in $(seq $((${#ALL[@]} - 1)) -1 0); do
        kill -TERM "${ALL[$i]}" 2>/dev/null || true
    done
    sleep 2
    for p in "${ALL[@]}"; do
        kill -KILL "$p" 2>/dev/null || true
    done
else
    echo "no live server pid in $PIDFILE"
fi

# Free the port (anything still bound to it).
if command -v lsof >/dev/null 2>&1; then
    PIDS="$(lsof -ti tcp:"$PORT" 2>/dev/null || true)"
    if [ -n "$PIDS" ]; then
        echo "freeing port $PORT (pids: $PIDS)"
        for p in $PIDS; do kill -TERM "$p" 2>/dev/null || true; done
        sleep 1
        for p in $PIDS; do kill -KILL "$p" 2>/dev/null || true; done
    fi
fi

rm -f "$PIDFILE"
echo "stopped."
