#!/usr/bin/env bash
# Continuous-batching throughput benchmark against a running Ripple + DFlash2
# server. Fires CONCURRENCY parallel request streams over example_prompts.txt
# and reports aggregate (suite) tok/s plus per-request decode stats.
#
# Env overrides:
#   BASE_URL     (default http://127.0.0.1:30000)
#   MODEL_NAME   (default ripple)
#   CONCURRENCY  parallel workers (default 8)
#   REQUESTS     total requests across all workers (default 24)
#   MAX_TOKENS   per request (default 128)
#   TEMPERATURE  (default 0.6)
#   PROMPTS_FILE (default scripts/example_prompts.txt)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export BASE_URL="${BASE_URL:-http://127.0.0.1:30000}"
export MODEL_NAME="${MODEL_NAME:-ripple}"
export CONCURRENCY="${CONCURRENCY:-8}"
export REQUESTS="${REQUESTS:-24}"
export MAX_TOKENS="${MAX_TOKENS:-128}"
export TEMPERATURE="${TEMPERATURE:-0.6}"
export PROMPTS_FILE="${PROMPTS_FILE:-$HERE/example_prompts.txt}"

exec python3 - <<'PY'
import json
import os
import statistics
import threading
import time
import urllib.request

BASE = os.environ["BASE_URL"]
MODEL = os.environ["MODEL_NAME"]
CONCURRENCY = int(os.environ["CONCURRENCY"])
REQUESTS = int(os.environ["REQUESTS"])
MAX_TOKENS = int(os.environ["MAX_TOKENS"])
TEMPERATURE = float(os.environ["TEMPERATURE"])
PROMPTS_FILE = os.environ["PROMPTS_FILE"]

with open(PROMPTS_FILE, encoding="utf-8") as f:
    prompts = [ln.strip() for ln in f if ln.strip()]
if not prompts:
    raise SystemExit(f"no prompts in {PROMPTS_FILE}")

_lock = threading.Lock()
next_idx = 0
done = 0
total_prompt = 0
total_completion = 0
wall_start = time.time()
req_times = []


def worker():
    global next_idx, done, total_prompt, total_completion
    while True:
        with _lock:
            if done >= REQUESTS:
                return
            i = next_idx
            next_idx += 1
            done += 1
        prompt = prompts[i % len(prompts)]
        payload = {
            "model": MODEL,
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": MAX_TOKENS,
            "temperature": TEMPERATURE,
        }
        req = urllib.request.Request(
            BASE + "/v1/chat/completions",
            data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json"},
        )
        t0 = time.time()
        try:
            with urllib.request.urlopen(req, timeout=900) as r:
                body = json.loads(r.read().decode())
        except Exception as e:
            with _lock:
                print(f"request {i} error: {e}")
            continue
        dt = time.time() - t0
        usage = body.get("usage", {})
        pt = usage.get("prompt_tokens", 0)
        ct = usage.get("completion_tokens", 0)
        with _lock:
            total_prompt += pt
            total_completion += ct
            req_times.append((dt, pt, ct))


threads = [threading.Thread(target=worker) for _ in range(CONCURRENCY)]
for t in threads:
    t.start()
for t in threads:
    t.join()

wall = time.time() - wall_start
all_tokens = total_prompt + total_completion
print(f"requests={done} concurrency={CONCURRENCY} prompts={len(prompts)}")
print(f"tokens: prompt={total_prompt} completion={total_completion} total={all_tokens}")
print(f"wall={wall:.1f}s")
if wall > 0:
    print(f"suite tok/s (incl prefill) = {all_tokens / wall:.1f}")
if req_times:
    comp_times = [dt * ct / max(ct, 1) for dt, pt, ct in req_times if ct]
    if comp_times:
        print(f"mean per-request decode tok/s = {statistics.mean(comp_times):.1f}")
        print(f"median per-request decode tok/s = {statistics.median(comp_times):.1f}")
    print(f"mean per-request wall = {statistics.mean(dt for dt, pt, ct in req_times):.2f}s")
PY
