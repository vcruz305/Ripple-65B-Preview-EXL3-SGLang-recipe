# Ripple-65B-Preview EXL3 SGLang recipe

Serves **[`vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw)** (SAGE-REXL3
quantized target) with the quantized **[`vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3)**
([`4.55bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw) EXL3 DFlash2 draft, recommended) on **SGLang `0.5.19`** through
the **[`vcruz305/sglang-exl3`](https://github.com/vcruz305/sglang-exl3)**
EXL3 plugin at commit **`5d1c9ef`**.

Measured on one **NVIDIA RTX PRO 6000 Blackwell (96 GB, `sm_120`)**:
**~64.8 tok/s greedy decode**, **~53.1 tok/s at `t=0.6`**, **~1,800 tok/s
cold prefill**, DFlash accept len **2.05–3.55**, and a **117,376-token full
KV pool** — with tool-call and reasoning parsers live.

## Status

Measured 2026-11-06/07 on one RTX PRO 6000 Blackwell 96 GB (`sm_120`). All
numbers below are **measured** (not estimates) from the exact scripts in this
repo. The recommended configuration is the [`5.41bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw) target + [`4.55bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw)
EXL3 DFlash2 draft.

## Headline results (SGLang 0.5.19 + sglang-exl3 `5d1c9ef`, tp=1)

Prompt sizes are the actual tokenized counts (the benchmark targets
519/2049/4099; the tokenizer yields 403/1564/3152). Decode tok/s uses
streaming TTFT with `stream_options={"include_usage": True}` (usage-exact
completion tokens; counting SSE chunks undercounts by ~accept_len under
DFlash).

| Config | Greedy decode 403/1564/3152 tok | `t=0.6` decode 403/1564/3152 tok | Cold prefill 403/1564/3152 tok | Accept len | Draft VRAM | KV pool (full / SWA) |
|---|---|---|---|---|---|---|
| **[EXL3 `4.55bpw` DFlash2 draft](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw) (recommended)** | **64.8 / 44.9 / 49.3 tok/s** | **53.1 / 41.2 / 51.3 tok/s** | **1,096.5 / 1,672.6 / 1,796.3 tok/s** | 2.05–3.55 | 2.19 GB | 117,376 / 93,888 |
| [BF16 DFlash2 draft](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2) | 59.3–60.9 / 41.5 / 45.5 tok/s | 31.8 / 33.2 / 42.9 tok/s | 1,086.5 / 1,662.6 / 1,788.9 tok/s | ~1.3–3.2 | 7.60 GB | 97,408 / 77,888 |
| [EXL3 `3.60bpw` DFlash2 draft](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.60bpw) | 28.7 / 25.2 / 23.1 tok/s (non-streaming 128 tok) | 28.5 / 25.0 / 24.9 | 992.7 / 1,323.4 / 1,366.6 | ~1.5–3.1 | 1.88 GB | 117,376 / 93,888 |
| [EXL3 `3.08bpw` DFlash2 draft](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.08bpw) | 41.6 / 24.6 / 19.0 tok/s (non-streaming 128 tok) | 24.6 / 31.8 / 22.8 | 999.1 / 1325.2 / 1367.2 | ~1.9–2.9 | 1.66 GB | 117,376 / 93,888 |
| [Target-only (`5.41bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw), no draft (baseline) | ~23.7 tok/s decode | — | ~3,275 tok/s prefill | n/a | — | 134,784 / 107,776 |
| Failure mode: BF16 stacked projections skipped | ~19.4 tok/s | — | — | 1.00 | — | — |
| Failure mode: draft `fc`/`down_proj` FP32 scaling omitted | ~20.2 tok/s | — | — | 1.00 | — | — |

`AGENTS.md` and `docs/MEASUREMENTS.md` carry the full per-prompt table, the
VRAM/context breakdown, and the optimization timeline behind the numbers.

## SixCat evaluation (SAGE-REXL3 target packs)

SixCat (challenge-v1, 20 items/category, `thinking=on, temp=0.6, seed=1`,
[DFlash2 BF16 draft](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2), full planner-granted context):

| Quant (bpw) | Overall | scored/n | knowledge | math | truth | instruct | code | tools |
|---|---|---|---|---|---|---|---|---|
| [**5.41 bpw** (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw) | **88.89%** | 118/120 | 83.3 | 100.0 | 80.0 | 85.0 | 95.0 | 90.0 |
| [**2.57 bpw** (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw) | 83.82% | 119/120 | 57.9 | 100.0 | 80.0 | 85.0 | 90.0 | 90.0 |
| [**1.95 bpw** (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw) | 78.64% | 118/120 | 63.2 | 95.0 | 73.7 | 80.0 | 75.0 | 85.0 |

Token-level fidelity of the [`5.41bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw) pack vs [Ricursive's official BF16
release](https://huggingface.co/ricursiveAI/Ripple-65B-Preview) (teacher-forced, full-vocabulary KL, assistant-turn tokens):
**99.34% top-1 agreement, 0.0005 mean KLD** overall; wiki1100 98.54% /
0.001269, long17k 98.70% / 0.001272. Full per-category/per-item degradation
analysis in `docs/SIXCAT_EVAL.md`.

## Contents

- `AGENTS.md` — instructions for AI agents setting up this recipe (definition
  of done, traps, verification commands).
- `docs/MEASUREMENTS.md` — full benchmark tables, VRAM/context sizing, failure
  modes, optimization timeline.
- `docs/SIXCAT_EVAL.md` — SixCat 3-way quant degradation + fidelity tables.
- `scripts/setup.sh` — idempotent environment build + `--check` preflight.
- `scripts/download.sh` — downloads target + `4.55bpw` draft packs.
- `scripts/serve.sh` — launches the SGLang server (env-overridable, `DRY_RUN=1` preview).
- `scripts/stop.sh` — cleanly stops the server tree and frees the port.
- `scripts/bench_decode.py` + `scripts/bench.sh` — deterministic greedy/sampled benchmark.
- `scripts/batch.sh` + `scripts/example_prompts.txt` — continuous-batching throughput.

## Hardware, engine, and checkpoints

| Item | Value |
|---|---|
| GPU | NVIDIA RTX PRO 6000 Blackwell, 96 GB (`sm_120`), tp=1 |
| Engine | SGLang `0.5.19`, torch `2.13.0+cu130` |
| Plugin | [`vcruz305/sglang-exl3`](https://github.com/vcruz305/sglang-exl3) @ `5d1c9ef` (merged to `master`) |
| Target pack | [`vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw) (EXL3, ~43 GB pack / 42.46 GB GPU-resident; shards 10, `quant_method: exl3`, `model_type: ricursive`) |
| Companion target packs | [`vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw) (32 GB-class), [`vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw) (24 GB-class) |
| Draft repo | [`vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3) — EXL3 [`4.55bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw) (recommended) / [`3.60bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.60bpw) / [`3.08bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.08bpw), plus [BF16 (`ricursiveAI/Ripple-65B-Preview-DFlash2`)](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2); 5 layers, `selector_rank 256`, `top_k 32`, target layers [1,20,39,58,77] |
| Upstream base | [`ricursiveAI/Ripple-65B-Preview`](https://huggingface.co/ricursiveAI/Ripple-65B-Preview) (Apache-2.0) + [`ricursiveAI/Ripple-65B-Preview-DFlash2`](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2) |

Architecture: dense 65B autoregressive, 80 layers, hidden 5120, GQA 80/8
heads (head_dim 128), intermediate 40960, hybrid sliding-window 1024 + full
attention every 5th layer, NoPE, value residuals, PeriNorm, vocab 100352,
max positions 2,097,152.

## Quick start

### Option A: One command (setup + download + serve)

`scripts/run.sh` clones and installs **[`vcruz305/sglang-exl3`](https://github.com/vcruz305/sglang-exl3)** and **[`turboderp-org/exllamav3`](https://github.com/turboderp-org/exllamav3)**, downloads the **[`5.41bpw` target pack](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw)** and **[`4.55bpw` EXL3 DFlash2 draft](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw)**, and starts the OpenAI-compatible server on `http://127.0.0.1:30000/v1`:

```bash
git clone https://github.com/vcruz305/Ripple-65B-Preview-EXL3-SGLang-recipe.git
cd Ripple-65B-Preview-EXL3-SGLang-recipe
bash scripts/run.sh

# Or select a smaller target quant (2.57bpw or 1.95bpw):
QUANT=2.57bpw bash scripts/run.sh
QUANT=1.95bpw bash scripts/run.sh
```

### Option B: Step by step

```bash
# 1. Build the environment (ExLlamaV3 from source, SGLang 0.5.19, https://github.com/vcruz305/sglang-exl3)
bash scripts/setup.sh            # or: bash scripts/setup.sh --check

# 2. Download target (5.41bpw) + draft (4.55bpw EXL3 DFlash2)
bash scripts/download.sh

# 3. Launch the server (OpenAI-compatible, DFLASH on, 131K context)
bash scripts/serve.sh
curl --fail-with-body http://127.0.0.1:30000/v1/models

# 4. Benchmark (greedy = AGENTS.md verification path)
GREEDY=1 bash scripts/bench.sh
#    or full greedy+sampled:
bash scripts/bench.sh

# 5. Continuous-batching throughput
bash scripts/batch.sh

# 6. Stop
bash scripts/stop.sh
```

`bash scripts/serve.sh` with `DRY_RUN=1` prints the exact launch command and
environment without starting anything.

## What `sglang-exl3` changes

The plugin adds `RicursiveForCausalLM` and `DFlash2DraftModel` support for
SGLang `0.5.19` (`src/sglang_exl3/models/ricursive.py`,
`src/sglang_exl3/models/dflash_exl3.py`, `src/sglang_exl3/dense.py`).

Fixes:

1. **BF16 stacked weight loader** — maps stacked `q/k/v → qkv_proj` and
   `gate/up → gate_up_proj` tensors in `dflash_exl3.py`'s `load_weights` for
   BF16 drafts (previously silently skipped → zero draft → accept len 1.00).
2. **Graph-safe EXL3 `lm_head` screen** in `sglang.srt.models.dflash`
   (plus the `logits_processor` twin) so the selector folds into the draft
   CUDA graph instead of the broken eager fallback (capture tensors were left
   uninitialized → garbage ids → `srcIndex < srcSelectDimSize` assert).
3. **Candidate-id clamp** on-device for the draft selector (graph-safe).
4. **`apply_kv_only` skip-Q path** — runs only the K/V shards of the
   quantized `qkv_proj`, skipping the Q GEMM (saves ~83.3% of QKV context
   materialization) for the target and the draft.
5. **Persistent 1D-flat contiguous workspace** for the EXL3 GEMM — buffers are
   always contiguous for any `(rows, cols).view`, never strided, never
   reallocated during CUDA graph capture (the earlier strided/2D workspace
   caused device-side asserts).
6. **Selective FP32 dynamic scaling** only where `layer._exl3_scale_input`
   is set (draft `fc` + `down_proj`); the target model's 640 linears (all
   RMSNorm + `activation_clamp`) pay zero scaling cost.

Speed optimizations:

1. **Fused `exl3_mgemm` across all 80 layers** — `(q_proj, g_proj)` (80/80
   layers), `(k_proj, v_proj)` with `x2_b=v16` value-residual input (80/80
   layers), `(gate_proj, up_proj)` (79/80 layers), plus the draft's
   `gate_up_proj` and k/v shards; on by default (`SGLANG_EXL3_MGEMM=1`),
   numerically identical (cos≈0.9999998 vs per-linear reference, maxdiff
   1.2e-4 fp16).
2. Multi-matrix launch batching — fewer kernel launches per layer; fresh
   per-call output buffers (no shared-workspace aliasing).
3. Bitwidth-agnostic per-shard trellis GEMM — reads `K` from each tensor's
   trellis shape (2/2.5/3/4/5/6-bit groups identically), so one code path
   serves all four draft quant levels and the target.

## Tuning knobs

| Env / flag | Default | Effect |
|---|---|---|
| `DRAFT_QUANT` | `exl3` | `unquant` selects the BF16 draft (also point `DRAFT_DIR` at the BF16 pack) |
| `DRAFT_DIR` | `models/draft-4.55bpw` | draft pack directory |
| `CTX_LEN` | `131072` | context length; KV pool binds at ~117K full tokens on 96 GB |
| `MEM_FRAC` | `0.82` | `--mem-fraction-static`; raise for shorter context, lower for more KV |
| `PORT` / `HOST` | `30000` / `127.0.0.1` | server bind |
| `MAX_REQS` | `8` | `--max-running-requests` |
| `SGLANG_EXL3_MGEMM` | `1` | 0 disables the fused `exl3_mgemm` path (slower, for debugging) |
| `--speculative-num-draft-tokens` | 16 | DFlash block size |
| `--speculative-draft-window-size` | 16384 | draft sliding window |
| `--cuda-graph-backend-prefill` | `disabled` | prefill eager, decode on CUDA graphs (measured config) |

Nulls/losses: the [`3.60bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.60bpw)/[`3.08bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.08bpw) drafts decode slower than the default
[`4.55bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw) draft and are provided for memory-constrained hosts, not as
recommended defaults.

## Platform traps

- **Import `torch` before `exllamav3_ext`** in any preflight or script — the
  compiled extension has no RPATH of its own. `scripts/setup.sh --check` does
  this in the correct order.
- **Do not build with the wrong `TORCH_CUDA_ARCH_LIST`** — use `12.0` for
  RTX PRO 6000 / Blackwell consumer (`sm_120`); `12.1a` is for GB10/DGX
  Spark (aarch64).
- **Do not count SSE chunks as tokens under DFlash** — a single chunk can
  carry 3–4 accepted tokens; always use `stream_options={"include_usage": True}`
  and `completion_tokens / (total_dt - ttft)`.
- **Do not stop the server by killing only port 30000** — SGLang spawns child
  scheduler/detokenizer processes that stay resident on the GPU (~83 GB VRAM);
  always use `bash scripts/stop.sh`.
- **Do not remove `_exl3_scale_input` from the draft `fc`/`down_proj`** —
  without per-row dynamic FP32 scaling, activations overflow FP16 into NaN on
  long prompts and collapse `accept len` to 1.00.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `CUDA error: misaligned address` in `exl3_gemm` | checkpoint tensors left on CPU — be on plugin `5d1c9ef` or later (`dense.py` moves trellis/suh/svh/mcg/mul1 to the current CUDA device at load) |
| `Assertion srcIndex < srcSelectDimSize failed` | `embed_tokens` treated as `lm_head`, or `should_apply_lm_head_quant_method` not patched in `sglang.srt.models.dflash` — both fixed at `5d1c9ef` |
| `ValueError: Mismatched Tensor on argument #1 … expected dtype=float16` in flashinfer `rmsnorm_cute` | `EXL3LinearMethod.apply` returned float16 into a bfloat16 RMSNorm — fixed in `dense.py` (`layer._exl3_out_dtype = params_dtype`) |
| BF16 draft: `accept rate: 0.00`, `accept len: 1.00`, ~19.4 tok/s | `stacked_params_mapping` not applied (draft on garbage weights) — plugin `5d1c9ef` |
| ~20.2 tok/s, `accept len` 1.00 | draft `fc`/`down_proj` FP32 scaling removed |
| `pure_decode` lands at ~19–24 tok/s with `accept len: 1.00` | speculative decoding not accepting — stop and check the two failure rows above |
| Server won't boot at full context | KV pool is the binding constraint — lower `CTX_LEN` or `MEM_FRAC` |

## Related repositories

| Repo | Role |
|---|---|
| [sglang-exl3](https://github.com/vcruz305/sglang-exl3) | the runtime fork this recipe builds: EXL3 plugin for SGLang (Ripple `RicursiveForCausalLM` / `DFlash2DraftModel` support, fused `exl3_mgemm`), pinned at `5d1c9ef` |
| [vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw) | 48 GB-class target pack served by this recipe |
| [vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw) | 32 GB-class companion target pack |
| [vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw) | 24 GB-class companion target pack |
| [vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3) | DFlash2 draft packs ([`4.55bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw) / [`3.60bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.60bpw) / [`3.08bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.08bpw) EXL3) |
| [ricursiveAI/Ripple-65B-Preview](https://huggingface.co/ricursiveAI/Ripple-65B-Preview) | upstream base model (Apache-2.0) |
| [ricursiveAI/Ripple-65B-Preview-DFlash2](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2) | upstream BF16 draft (Apache-2.0) |

## Credits and upstream work

**ExLlamaV3 by Turboderp ([@turboderp](https://github.com/turboderp-org/exllamav3)).**
The EXL3 trellis format, the MCG/mul1 codebooks, the quantization method, and
the reference kernels are theirs. MIT, Copyright (c) 2025 Turboderp.

**[SGLang](https://github.com/sgl-project/sglang)** is the serving engine this
recipe runs on.

**Ripple-65B-Preview** and **Ripple-65B-Preview-DFlash2** are by Ricursive
Intelligence (Apache-2.0). SAGE-REXL3 target packs and the EXL3-quantized
DFlash2 drafts are by vcruz305.

## License

MIT for the scripts and notes in this repo (see `LICENSE`). Weights are
**not** redistributed here — pull them from Hugging Face and respect the
upstream licenses (Apache-2.0 for the base model; the SAGE-REXL3 packs are
Apache-2.0). SGLang, ExLlamaV3/EXL3, and `sglang-exl3` have their own
licenses.
