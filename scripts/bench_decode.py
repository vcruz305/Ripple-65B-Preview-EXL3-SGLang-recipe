#!/usr/bin/env python3
"""Clean decode + prefill benchmark for Ripple + DFlash2 on SGLang.

- Cold prefill tok/s via max_tokens=1 at prompt sizes 519/2049/4099.
- Pure decode tok/s via streaming TTFT: decode_dt = total_dt - ttft.
- Tool-call + reasoning correctness probes.

Env overrides:
    BASE_URL    (default http://127.0.0.1:30000)
    MODEL_NAME  (default ripple)
"""
import argparse
import json
import random
import sys
import time
import urllib.request

BASE = "http://127.0.0.1:30000"
MODEL = "ripple"


def _req(path, payload, stream=False):
    r = urllib.request.Request(BASE + path, data=json.dumps(payload).encode(),
                               headers={"Content-Type": "application/json"})
    return urllib.request.urlopen(r, timeout=900)


def post(path, payload):
    with _req(path, payload) as r:
        return json.loads(r.read().decode())


def chat(prompt, max_tokens=128, temperature=0.0, tools=None, tool_choice=None):
    msg = {"model": MODEL, "messages": [{"role": "user", "content": prompt}],
           "max_tokens": max_tokens, "temperature": temperature}
    if tools is not None:
        msg["tools"] = tools
        msg["tool_choice"] = tool_choice or "auto"
    return post("/v1/chat/completions", msg)


def chat_stream_decode(prompt, max_tokens=128, temperature=0.0):
    """Return (ttft, total_dt, completion_tokens, pure_decode_tps).

    Uses stream_options.include_usage so completion_tokens is exact. Under
    DFlash2 speculative decoding a single SSE delta can carry several accepted
    tokens, so counting chunks undercounts by ~accept_len; the usage chunk is
    authoritative.
    """
    msg = {"model": MODEL, "messages": [{"role": "user", "content": prompt}],
           "max_tokens": max_tokens, "temperature": temperature, "stream": True,
           "stream_options": {"include_usage": True}}
    t0 = time.time()
    ttft = None
    chunks = 0
    ct = 0
    text_parts = []
    with _req("/v1/chat/completions", msg) as resp:
        for raw in resp:
            line = raw.decode("utf-8", "ignore").strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == "[DONE]":
                break
            try:
                obj = json.loads(data)
            except Exception:
                continue
            usage = obj.get("usage")
            if usage:
                ct = usage.get("completion_tokens", ct)
            delta = obj.get("choices", [{}])[0].get("delta", {}) if obj.get("choices") else {}
            piece = delta.get("content") or delta.get("reasoning_content") or ""
            if piece and ttft is None:
                ttft = time.time() - t0
            if piece:
                chunks += 1
                text_parts.append(piece)
    total = time.time() - t0
    ttft = ttft if ttft is not None else total
    if not ct:
        ct = chunks
    decode_dt = max(total - ttft, 1e-6)
    return ttft, total, ct, ct / decode_dt


_rnd = random.Random(0)
_WORDS = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", "iota",
          "kappa", "lambda", "mu", "nu", "xi", "omicron", "pi", "rho", "sigma", "tau",
          "upsilon", "phi", "chi", "psi", "omega"]


def make_prompt(n):
    target = int(n * 3.4)
    s = []
    tot = 0
    while tot < target:
        w = _rnd.choice(_WORDS)
        s.append(w)
        tot += len(w) + 1
    return " ".join(s)


def main():
    global BASE, MODEL
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-url", default=None)
    ap.add_argument("--model", default=None)
    ap.add_argument("--max-tokens", type=int, default=128)
    ap.add_argument("--greedy", action="store_true", help="only t=0.0 (skip sampling)")
    args = ap.parse_args()
    BASE = args.base_url or BASE
    MODEL = args.model or MODEL
    out = args.max_tokens
    temps = (0.0,) if args.greedy else (0.0, 0.6)
    print("=== COLD PREFILL (max_tokens=1) ===", flush=True)
    for n in (519, 2049, 4099):
        p = make_prompt(n)
        t0 = time.time()
        r = chat(p, max_tokens=1)
        dt = time.time() - t0
        pt = r["usage"]["prompt_tokens"]
        print(f"PREFILL {n}: {pt}tok {dt:.2f}s = {pt/dt:.1f} tok/s", flush=True)
    print("=== DECODE via streaming TTFT ===", flush=True)
    for n in (519, 2049, 4099):
        p = make_prompt(n)
        for temp in temps:
            ttft, total, ct, tps = chat_stream_decode(p, max_tokens=out, temperature=temp)
            print(f"DECODE n={n} t={temp}: ttft={ttft:.2f}s total={total:.2f}s "
                  f"chunks={ct} pure_decode={tps:.1f} tok/s", flush=True)
    print("=== TOOL CALL ===", flush=True)
    tools = [{"type": "function", "function": {"name": "get_weather", "description": "Get weather",
        "parameters": {"type": "object", "properties": {"city": {"type": "string"}}, "required": ["city"]}}}]
    r = post("/v1/chat/completions", {"model": MODEL, "messages": [{"role": "user", "content": "What is the weather in Paris?"}],
        "tools": tools, "tool_choice": "required", "max_tokens": 80, "temperature": 0})
    print(json.dumps(r["choices"][0]["message"])[:400], flush=True)
    print("=== REASONING ===", flush=True)
    r = chat("Solve 17*23 step by step.", max_tokens=128)
    print(r["choices"][0]["message"]["content"][:200], flush=True)


if __name__ == "__main__":
    main()
