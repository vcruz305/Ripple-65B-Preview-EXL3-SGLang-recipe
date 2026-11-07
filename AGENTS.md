# AGENTS.md: instructions for AI agents setting up this recipe

Read this before running anything in this repository.

## Required repositories and model links

| Component | URL | What `scripts/run.sh` does with it |
|---|---|---|
| **SGLang EXL3 plugin (`vcruz305/sglang-exl3`)** | **https://github.com/vcruz305/sglang-exl3** | Cloned into `.deps/sglang-exl3` and registered into `.venv` by `scripts/setup.sh` |
| **ExLlamaV3 CUDA kernels (`turboderp-org/exllamav3`)** | **https://github.com/turboderp-org/exllamav3** | Cloned into `.deps/exllamav3` and compiled from source (`exllamav3_ext`) by `scripts/setup.sh` |
| **Target pack — 5.41 bpw (default, 48 GB+)** | **https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw** | Downloaded to `models/target` by `scripts/download.sh` (`QUANT=5.41bpw`) |
| **Target pack — 2.57 bpw (32 GB-class)** | **https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw** | Downloaded to `models/target` when `QUANT=2.57bpw` |
| **Target pack — 1.95 bpw (24 GB-class)** | **https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw** | Downloaded to `models/target` when `QUANT=1.95bpw` |
| **DFlash2 EXL3 drafts (`4.55bpw`, `3.60bpw`, `3.08bpw`)** | **https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3** | Subfolder [`4.55bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw) downloaded to `models/draft-4.55bpw` by `scripts/download.sh` |
| **DFlash2 BF16 draft (upstream optional)** | **https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2** | Downloaded when `DRAFT_SUBDIR=bf16` |
| **Upstream BF16 base model** | **https://huggingface.co/ricursiveAI/Ripple-65B-Preview** | Base model reference |

## The one supported path (`scripts/run.sh`)

This recipe serves **[`vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw)** with the quantized **[`vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3) ([`4.55bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw))** speculative drafter on **SGLang 0.5.19** through the **[`vcruz305/sglang-exl3`](https://github.com/vcruz305/sglang-exl3)** plugin and **ExLlamaV3** built from source.

To install everything (`SGLang 0.5.19` + `vcruz305/sglang-exl3` + `ExLlamaV3`), download the target and DFlash2 draft packs, and launch the server in one command:

```bash
bash scripts/run.sh

# Or with a smaller target quant (2.57bpw or 1.95bpw):
QUANT=2.57bpw bash scripts/run.sh
QUANT=1.95bpw bash scripts/run.sh
```

Or run the three stages individually in order:

```bash
# 1. Build ExLlamaV3 from source for the local GPU arch and install SGLang 0.5.19 + https://github.com/vcruz305/sglang-exl3
bash scripts/setup.sh

# 2. Download the 5.41bpw target pack and the 4.55bpw EXL3 DFlash2 draft pack
bash scripts/download.sh

# 3. Launch the OpenAI-compatible server on http://127.0.0.1:30000/v1 (DFlash2 ON, 131K context)
bash scripts/serve.sh
```

The served model ID is `ripple`. Check readiness with:

```bash
curl --fail-with-body http://127.0.0.1:30000/v1/models
```

## Definition of done

Verify the running server with the deterministic greedy benchmark (`GREEDY=1`):

```bash
GREEDY=1 bash scripts/bench.sh
```

On a single NVIDIA RTX PRO 6000 Blackwell (96 GB, `sm_120`, `TP=1`, CUDA graphs enabled, `4.55bpw` EXL3 DFlash2 draft), `scripts/bench.sh` prints:

- **Cold prefill (`max_tokens=1`):**
  - `PREFILL 519` (403 tok): `~1,095–1,120 tok/s` (`0.36–0.37s`)
  - `PREFILL 2049` (1,564 tok): `~1,670–1,680 tok/s` (`0.93–0.94s`)
  - `PREFILL 4099` (3,152 tok): `~1,795–1,805 tok/s` (`1.75s`)
- **Pure decode (`t=0.0` greedy, 128 completion tokens after streaming TTFT):**
  - `DECODE n=519 t=0.0`: **`~64.8 tok/s`** (`ttft ~0.43s`, `total ~2.41s`, `accept len ~3.55`)
  - `DECODE n=2049 t=0.0`: **`~44.9 tok/s`** (`ttft ~1.00s`, `total ~3.84s`)
  - `DECODE n=4099 t=0.0`: **`~49.3 tok/s`** (`ttft ~1.82s`, `total ~4.41s`)
- **Sampled decode (`t=0.6`, when run without `GREEDY=1`):**
  - `DECODE n=519 t=0.6`: **`~53.1 tok/s`**
  - `DECODE n=2049 t=0.6`: **`~41.2 tok/s`**
  - `DECODE n=4099 t=0.6`: **`~51.3 tok/s`**
- **Capabilities:**
  - `=== TOOL CALL ===`: valid `get_weather` call with `{"city": "Paris"}` via `--tool-call-parser ripple`
  - `=== REASONING ===`: step-by-step `17*23 = 391` separated into `reasoning_content` and `content` via `--reasoning-parser ripple`

If `pure_decode` lands around **`~19–24 tok/s`** with `accept len: 1.00`, speculative decoding is not accepting tokens — stop and check the traps below. Do not report a ~20 tok/s fallback run as a passing deployment.

## Do not

- **Do not launch bare `python -m sglang.launch_server`.** Always launch via `scripts/serve.sh` (which runs `scripts/serve_ripple.py`). `serve_ripple.py` registers `sglang_exl3`, `RicursiveForCausalLM`, the `DFlash2DraftModel` EXL3 weight/graph hooks, and the `ripple` tool-call and reasoning parsers before SGLang parses model arguments.
- **Do not run without the DFlash2 draft model.** Target-only decode without DFlash2 is `~23.7 tok/s`. Always keep `--speculative-algorithm DFLASH --speculative-num-draft-tokens 16` enabled.
- **Do not count SSE chunks (`chunks`) as generated tokens when benchmarking DFlash2.** With speculative decoding (`accept len ~2.1–3.55`), a single SSE `delta.content` chunk contains multiple accepted tokens (`3–4` tokens per chunk). Counting chunks understates decode speed by ~3x (`~19 chunks/s` vs `~64.8 tok/s`). Always pass `"stream_options": {"include_usage": True}` and compute `completion_tokens / (total_dt - ttft)`.
- **Do not set `SGLANG_EXL3_MGEMM=0`.** The plugin defaults `SGLANG_EXL3_MGEMM=1` on, fusing `(q_proj, g_proj)` (80/80 layers), `(k_proj, v_proj)` with value residuals (80/80 layers), and `(gate_proj, up_proj)` (79/80 layers) plus the draft's `gate_up_proj` and `(k, v)` shards into multi-matrix `exl3_mgemm` launches.
- **Do not remove `_exl3_scale_input` on `DFlashDraftModel.fc` and `down_proj`.** Unlike the 80-layer target model (which has PeriNorm `RMSNorm` and `ffn_activation_clamp=16.0`), the 5-layer DFlash2 draft's `fc` (`25,600 -> 5,120`) receives raw un-normalized target residual streams before `hidden_norm`, and `down_proj` (`40,960 -> 5,120`) is un-clamped. Without per-row dynamic FP32 scaling on those 6 draft projections, activations overflow FP16 (`65,504`) into `NaN` on long prompts and collapse `accept len` to `1.00`.
- **Do not rewrite or modify the pack in place.** SGLang loads the native SAGE-REXL3 safetensors shards directly.
- **Do not stop the server by only killing port 30000.** SGLang spawns child `sglang::scheduler` and `sglang::detokenizer` processes that remain resident on the GPU (~83 GB VRAM) if only the HTTP frontend dies. Always use `bash scripts/stop.sh` before restarting.

## Sizing (context, memory, and draft choice)

On a single 96 GB GPU (`TP=1`, `--mem-fraction-static 0.82`, `--context-length 131072`):

- **Target weights ([`5.41bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw)):** `42.46 GB`
- **Draft weights ([`4.55bpw` EXL3 DFlash2](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/4.55bpw), recommended):** `2.19 GB` → leaves **`117,376` full-attention tokens / `93,888` sliding-window tokens** (`30.11 GB` hybrid `SWAKVPool`) and `~83.1 GB` total VRAM used after CUDA graph capture. Other quantized draft options in the same repo: [`3.60bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.60bpw) (`1.88 GB`) and [`3.08bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3/tree/main/3.08bpw) (`1.66 GB`).
- **Draft weights ([`BF16` DFlash2](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2), optional):** `7.60 GB` → leaves `97,408` full-attention tokens / `77,888` SWA tokens. It uses `5.41 GB` more VRAM and decodes slightly slower (`60.9 tok/s` vs `64.8 tok/s` greedy) because every 5-layer draft step reads `3.5x` more weight bytes.
- For smaller GPUs, companion target packs are available at **[`2.57bpw` (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw)** (32 GB-class) and **[`1.95bpw` (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw)** (24 GB-class, `14.5 GiB` GPU-resident weights with protected `L00–L07`).

Override sizing via environment variables (`MODEL_DIR`, `DRAFT_DIR`, `DRAFT_QUANT=exl3|unquant`, `CTX_LEN`, `MEM_FRAC`, `MAX_REQS`, `PORT`), or preview the exact launch command without starting the server:

```bash
DRY_RUN=1 bash scripts/serve.sh
```

## Verify your environment

```bash
bash scripts/setup.sh --check
```

This imports `torch` before `exllamav3_ext` (whose `.so` relies on Torch's loaded dynamic libraries), verifies `exl3_gemm` and `exl3_mgemm` symbol availability, checks `sglang==0.5.19`, and confirms `sglang_exl3`'s `RicursiveForCausalLM` and `DFlash2DraftModel` hooks import cleanly.

## If something fails

- **`CUDA error: misaligned address` in `exl3_gemm`:** checkpoint tensors yielded by `safetensors_weights_iterator` were left on CPU. Ensure you are on `vcruz305/sglang-exl3` commit `5d1c9ef` or later (`dense.py` moves `trellis`, `suh`, `svh`, `mcg`, and `mul1` onto the current CUDA device at load).
- **`Assertion srcIndex < srcSelectDimSize failed` in `indexSelectSmallIndex`:**
  1. Target `embed_tokens` was treated as `lm_head` (`VocabParallelEmbedding` dummy weight), OR
  2. `sglang.srt.models.dflash.should_apply_lm_head_quant_method` was not patched alongside `logits_processor.should_apply_lm_head_quant_method`, leaving `can_fold_into_draft_graph=False` and reading uninitialized `self.candidate_out` memory during draft CUDA graph replay. Both are fixed in `sglang-exl3` `5d1c9ef`.
- **`ValueError: Mismatched Tensor on argument #1 ... expected dtype=float16` in `flashinfer` `rmsnorm_cute`:** `EXL3LinearMethod.apply` returned `float16` into a `bfloat16` `RMSNorm`. Fixed in `dense.py` (`layer._exl3_out_dtype = params_dtype`).
- **BF16 draft shows `accept rate: 0.00` (`accept len: 1.00`, `~19.4 tok/s`):** `stacked_params_mapping` (`qkv_proj` ← `q/k/v_proj`, `gate_up_proj` ← `gate/up_proj`) was not applied to `.weight` tensors in `dflash_exl3.py`. Fixed in `5d1c9ef`.
