# Measurements — Ripple-65B-Preview SAGE-REXL3 + DFlash2 on SGLang 0.5.19

All numbers below are **measured** on one NVIDIA RTX PRO 6000 Blackwell
(96 GB, `sm_120`) with `TP=1` and CUDA graphs enabled (target-verify +
draft-verify), unless stated otherwise.

| Component | Value |
|---|---|
| GPU | NVIDIA RTX PRO 6000 Blackwell, 96 GB (`sm_120`) |
| Engine | SGLang `0.5.19` |
| Plugin | [`vcruz305/sglang-exl3`](https://github.com/vcruz305/sglang-exl3) @ `5d1c9ef` (`feat/ripple-65b-dflash2`, now merged to `master`) |
| Torch | `2.13.0+cu130` |
| Target pack | [`vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw) (EXL3, ~43 GB pack / 42.46 GB GPU-resident) |
| Companion target packs | [`vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw) (32 GB-class), [`vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw) (24 GB-class) |
| Draft packs | [`vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3) — [`4.55bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw) / [`3.60bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.60bpw) / [`3.08bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.08bpw) EXL3, plus [BF16 (`ricursiveAI/Ripple-65B-Preview-DFlash2`)](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2) |
| Draft topology | 5 layers, `selector_rank 256`, `top_k 32`, `target_layer_ids [1,20,39,58,77]` |
| Context length | `--context-length 131072` |
| Memory | `--mem-fraction-static 0.82` |
| Speculative | `DFLASH`, `--speculative-num-draft-tokens 16`, draft window 16384 |
| Benchmark flags | `stream_options={"include_usage": True}`; decode tok/s = `completion_tokens / (total_dt - ttft)` |

## Launch command (as benchmarked)

```bash
export PYTHONPATH="${PWD}:${PYTHONPATH:-}" SGLANG_EXL3_MGEMM=1
python scripts/serve_ripple.py \
  --model-path "$MODEL_DIR" \
  --speculative-draft-model-path "$DRAFT_DIR" \
  --speculative-draft-model-quantization exl3
# BF16 draft: --speculative-draft-model-quantization unquant
```

Full default flag set baked into `scripts/serve_ripple.py`:
`--tp-size 1 --attention-backend triton --speculative-draft-attention-backend triton
--speculative-algorithm DFLASH --speculative-num-draft-tokens 16
--speculative-draft-window-size 16384 --mem-fraction-static 0.82
--page-size 64 --tool-call-parser ripple --reasoning-parser ripple`.

## VRAM & KV pool (5.41bpw target + EXL3 draft, tp=1)

| Component | Value |
|---|---|
| Target weights load ([`5.41bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw)) | 42.46 GB (avail 93.96 → 51.50 GB) |
| Draft weights ([`4.55bpw` EXL3](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw)) | 2.19 GB |
| Draft weights ([`3.60bpw` EXL3](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.60bpw)) | 1.88 GB |
| Draft weights ([`3.08bpw` EXL3](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.08bpw)) | 1.66 GB |
| Draft weights ([BF16](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2)) | 7.60 GB |
| KV pool (`4.55bpw` draft) | **117,376 full / 93,888 SWA tokens** (30.11 GB SWAKVPool) |
| KV pool (BF16 draft) | 97,408 full / 77,888 SWA tokens |
| KV pool (no draft) | 134,784 full / 107,776 SWA tokens |
| CUDA graph (target verify + draft verify) | ~0.63 GB |
| Total GPU used at serve (`4.55bpw` draft) | ~83 GB / 97.9 GB |
| No-draft decode baseline | ~23.7 tok/s |

On 96 GB the binding constraint is the hybrid sliding-window KV pool
(16 full-attention NoPE layers dominate). ~117K full-context tokens is the
largest clean boot at `--mem-fraction-static 0.82` with the 16-token DFlash
block.

## Headline ([4.55bpw EXL3 DFlash2 draft](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw) — recommended)

Prompt sizes are the **actual tokenized** counts (the generator targets
519/2049/4099; the tokenizer yields 403/1564/3152). Decode uses streaming
TTFT with `stream_options.include_usage` (usage-exact completion tokens;
counting SSE chunks undercounts by ~accept_len under DFlash).

| Metric | 403 tok | 1564 tok | 3152 tok |
|---|---|---|---|
| Cold prefill tok/s | 1096.5 | 1672.6 | 1796.3 |
| Decode greedy tok/s | **64.8** | 44.9 | 49.3 |
| Decode temp=0.6 tok/s | 53.1 | 41.2 | 51.3 |
| DFlash accept len (server) | ~2.0–2.7 | ~1.4–2.7 | ~2.3–2.7 |

Usage-exact client-side accept len reached **3.55** at the 403-token prompt;
server-logged accept len across the full run ranged 1.85–3.17.
`--cuda-graph-backend-prefill disabled` (prefill runs eagerly; decode runs on
CUDA graphs).

## [BF16 draft (`ricursiveAI/Ripple-65B-Preview-DFlash2`)](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2) (optional)

| Metric | 403 tok | 1564 tok | 3152 tok |
|---|---|---|---|
| Cold prefill tok/s | 1086.5 | 1662.6 | 1788.9 |
| Decode greedy tok/s | 59.3–60.9 | 41.5 | 45.5 |
| Decode temp=0.6 tok/s | 31.8 | 33.2 | 42.9 |
| DFlash accept len (server) | ~1.3–3.2 | ~1.7–2.4 | ~1.9–2.7 |

The BF16 draft uses 5.41 GB more VRAM than the [4.55bpw EXL3 draft](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw) and reads
~3.5× more weight bytes per 5-layer draft step.

## [3.60bpw EXL3 draft](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.60bpw)

Non-streaming, 128-token completions:

- Prefill: 992.7 / 1323.4 / 1366.6 tok/s; decode greedy 28.7 / 25.2 /
  23.1 tok/s; temp=0.6 28.5 / 25.0 / 24.9; accept len ~1.5–3.1.

## [3.08bpw EXL3 draft](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.08bpw)

Non-streaming, 128-token completions:

- Prefill: 999.1 / 1325.2 / 1367.2 tok/s; decode greedy 41.6 / 24.6 /
  19.0 tok/s; temp=0.6 24.6 / 31.8 / 22.8; accept len ~1.9–2.9.

## Failure modes (do not ship these)

| Symptom | Root cause | Fixed in |
|---|---|---|
| ~19.4 tok/s, `accept len 1.00` (BF16 draft) | `stacked_params_mapping` (`qkv_proj` ← `q/k/v_proj`, `gate_up_proj` ← `gate/up_proj`) not applied to `.weight` tensors → draft runs on zero/garbage weights | `5d1c9ef` (`dflash_exl3.py`) |
| ~20.2 tok/s, `accept len 1.00` | `_exl3_scale_input` removed from draft `fc` / `down_proj` → FP16 overflow (`65,504`) → NaN on long prompts | `5d1c9ef` (`dense.py`) |

## Correctness probes (all drafts)

- Chat/reasoning coherent (`17*23 = 391` step-by-step; `reasoning_content`
  separated from `content`).
- Strict tool call (`--tool-call-parser ripple`) returns valid
  `get_weather {"city":"Paris"}`.

## Optimization timeline (before → after)

| Change | Effect |
|---|---|
| BF16 stacked-projection load fix | accept len 1.00 → ~2.8; decode 19.4 → ~48 tok/s |
| Graph-safe EXL3 lm_head screen + candidate clamp | eliminated `srcIndex < srcSelectDimSize` CUDA asserts |
| Global FP32 scaling → selective (draft fc/down only) | kept accept len while removing 2,560 elementwise launches/pass |
| Fused `exl3_mgemm` pairs (on by default) | fewer GEMM launches; k/v fused across all 80 layers via `x2_b` value-residual input; fresh per-call output buffers (no workspace aliasing); numerically identical (cos≈0.9999998, maxdiff 1.2e-4 fp16) |
| Streaming TTFT + usage-exact tokens | decode measured correctly (was undercounted ~3×) |
| Final decode (greedy, 128 tok) | up to **64.8 tok/s** at 403 prompt tokens |

## Known limitations

- Full 2M context is not reachable on 96 GB; ~117K full-context tokens is
  the practical ceiling for this pack on a single RTX PRO 6000.
- `3.60bpw` / `3.08bpw` drafts decode slower than the default `4.55bpw`
  draft (acceptance degrades as draft bpw drops); they are listed for
  memory-constrained hosts, not recommended defaults.
