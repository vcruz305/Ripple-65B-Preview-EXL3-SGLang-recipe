# SixCat evaluation — Ripple-65B-Preview SAGE-REXL3 (3-way quant degradation)

Method (identical for all runs): [DFlash2
BF16 draft (`ricursiveAI/Ripple-65B-Preview-DFlash2`)](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2) (or quantized EXL3 drafts in [`vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3`](https://huggingface.co/vcruz305/Ripple-65B-Preview-DFlash2-SAGE-REXL3)), `--policy custom --thinking on --temperature 0.6 --seed 1
--concurrency 1 --request-timeout 1800 --max-minutes 0`, budgets
knowledge=8192 / math=16384 / truth=8192 / instruct=32768 / code=32768 /
tools=16384, 20 items/category (challenge-v1 selection, fingerprint
`05c04833fcdb`), full context, one `--retry remaining` attempted in-chain per
run. All scores are provisional (PARTIAL/PROVISIONAL) exactly as the 5.41
baselines. The 5.41 runs used the same per-category-20 invocation as the
2.57 / 1.95 runs.

## Summary

| Quant (bpw) | Overall | scored/n | knowledge | math | truth | instruct | code | tools | completion tok | trunc I/C | remaining | failed |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [**5.41 bpw** (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw) | **88.89** | 118/120 | 83.3 | 100.0 | 80.0 | 85.0 | 95.0 | 90.0 | 269,835 | I2/C1 | 2 | 13 |
| [**2.57 bpw** (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw) | **83.82** | 119/120 | 57.9 | 100.0 | 80.0 | 85.0 | 90.0 | 90.0 | 254,726 | I1/C1 | 1 | 19 |
| [**1.95 bpw** (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw) | **78.64** | 118/120 | 63.2 | 95.0 | 73.7 | 80.0 | 75.0 | 85.0 | 389,619 | I4/C4 | 2 | 25 |

Overall: 88.89 ([5.41](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw)) → 83.82 ([2.57](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw)) → 78.64 ([1.95](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw)). Δ = −5.07 →
−10.25 vs 5.41.

## Per-category scores (Δ vs [5.41](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw))

| Category | [5.41 bpw](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw) | [2.57 bpw](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw) (Δ) | [1.95 bpw](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw) (Δ) |
|---|---|---|---|
| knowledge | 83.3 | 57.9 (−25.4) | 63.2 (−20.2) |
| math | 100.0 | 100.0 (±0.0) | 95.0 (−5.0) |
| truth | 80.0 | 80.0 (±0.0) | 73.7 (−6.3) |
| instruct | 85.0 | 85.0 (±0.0) | 80.0 (−5.0) |
| code | 95.0 | 90.0 (−5.0) | 75.0 (−20.0) |
| tools | 90.0 | 90.0 (±0.0) | 85.0 (−5.0) |

## [2.57 bpw (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw) result

- Pack: [`2.57 bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-2.57bpw) + [DFlash2 BF16 draft](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2);
  policy custom thinking=on
  temp=0.6 seed=1; budgets knowledge=8192 / math=16384 / truth=8192 /
  instruct=32768 / code=32768 / tools=16384; limit 20/category
  (challenge-v1, fingerprint `05c04833fcdb`); concurrency 1;
  request-timeout 1800.
- Overall: 83.82 (provisional, PARTIAL/PROVISIONAL as with baseline).
- Category scores: knowledge 57.9 (11/19), math 100.0 (20/20), truth 80.0
  (16/20), instruct 85.0 (17/20, 1 truncated), code 90.0 (18/20, 1
  truncated), tools 90.0 (18/20).
- Scored 119/120; remaining 1 (knowledge/winogrande:15); failed 19; loops 0;
  empty answers: instruct 1, code 1.
- Completion tokens 254,726 (120 responses, 1 error).

## [1.95 bpw (`vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw`)](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw) result

- Pack: [`1.95 bpw`](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-1.95bpw) + [DFlash2 BF16 draft](https://huggingface.co/ricursiveAI/Ripple-65B-Preview-DFlash2);
  policy custom thinking=on temp=0.6 seed=1;
  budgets knowledge=8192 / math=16384 / truth=8192 / instruct=32768 /
  code=32768 / tools=16384; limit 20/category (challenge-v1, fingerprint
  `05c04833fcdb`); concurrency 1; request-timeout 1800.
- Overall: 78.64 (provisional, PARTIAL/PROVISIONAL).
- Category scores: knowledge 63.2 (12/19), math 95.0 (19/20), truth 73.7
  (14/19), instruct 80.0 (16/20, 4 truncated), code 75.0 (15/20, 4
  truncated), tools 85.0 (17/20).
- Scored 118/120; remaining 2 (knowledge/winogrande:15, truth/tqa:3);
  failed 25; loops 0; empty answers: instruct 4, code 4.
- Completion tokens 389,619 (120 responses, 2 errors).

## Degradation analysis

- **knowledge** 83.3 → 57.9 → 63.2: largest single drop at 2.57 (−25.4) —
  7 items flip PASS→FAIL (mmlu:7, hellaswag:17, winogrande:13, winogrande:1,
  tqa:10, ifeval:1300, HumanEval/32); at 1.95 knowledge partially recovers
  (57.9→63.2, mmlu:7 back to PASS) but hellaswag:10 additionally fails.
  2 items unscored in the 5.41 baseline (hellaswag:16, winogrande:15) score
  FAIL at 2.57/1.95.
- **math** 100 → 100 → 95: first failure at 1.95 (gsm:17 flips PASS→FAIL).
- **truth** 80 → 80 → 73.7: same score at 2.57 but different items (tqa:10
  PASS→FAIL); at 1.95 tqa:15 flips PASS→FAIL, tqa:19 FAIL (was PASS at
  2.57), tqa:3 becomes unscored (remaining).
- **instruct** 85 → 85 → 80: truncations grow 2 → 1 → 4; ifeval:1379 &
  ifeval:1000 flip PASS→TRUNC at 1.95; ifeval:1300 (FAIL at 2.57) also TRUNC
  at 1.95; two 5.41-truncated items (ifeval:1040, ifeval:1287) pass at
  2.57/1.95.
- **code** 95 → 90 → 75: HumanEval/32 flips PASS→FAIL at 2.57 and stays FAIL
  at 1.95; at 1.95 HumanEval/134, /83, /129 flip PASS→TRUNC and truncation
  count rises to 4 (from 1). Largest categorical drop at 1.95 (−20).
- **tools** 90 → 90 → 85: tool:two exact reads flips PASS→FAIL at 1.95.

Item-level flips:

- PASS→FAIL at 2.57 (7): knowledge/mmlu:7, knowledge/hellaswag:17,
  knowledge/winogrande:13, knowledge/winogrande:1, truth/tqa:10,
  instruct/ifeval:1300, code/HumanEval/32.
- PASS→FAIL/TRUNC at 1.95 (10 new vs 2.57): knowledge/hellaswag:10,
  math/gsm:17, truth/tqa:15, truth/tqa:19, instruct/ifeval:1379 (TRUNC),
  instruct/ifeval:1000 (TRUNC), code/HumanEval/134 (TRUNC), code/HumanEval/83
  (TRUNC), code/HumanEval/129 (TRUNC), tools/tool:two exact reads.
- Cumulative 5.41-PASS items no longer passing at 1.95 (15): hellaswag:10,
  hellaswag:17, winogrande:13, winogrande:1, gsm:17, tqa:10, tqa:15,
  ifeval:1379, ifeval:1000, ifeval:1300, HumanEval/32, HumanEval/134,
  HumanEval/83, HumanEval/129, tool:two exact reads.
- Recoveries (FAIL→PASS): mmlu:8 (PASS at 1.95), mmlu:7 (PASS at 1.95
  after FAIL at 2.57), tqa:19 (PASS at 2.57, back to FAIL at 1.95),
  ifeval:1040 (PASS at 2.57 and 1.95), ifeval:1287 (PASS at 1.95 after TRUNC
  in 5.41/2.57).

## Caveats

- All four runs are provisional/PARTIAL (scope unfinished): truncations in
  instruct/code make those scores less reliable (flagged by the harness
  itself); final overalls use only scored items, so the 1–2 remaining items
  per run are excluded.
- The truncation rise at 1.95 (instruct 1→4, code 1→4) plus its higher
  completion-token volume (389.6k vs 254–270k) and highest throughput (178.6
  suite tok/s) indicate 1.95 bpw generates longer outputs but more often
  fails to finish within the per-category token budgets.
- Items unscored in some runs (knowledge/hellaswag:16, knowledge/winogrande:15,
  truth/tqa:3) are excluded from that run's score.
- Seed=1, temperature=0.6, thinking=on with DFlash2 BF16 draft are identical
  across all runs; identical challenge-v1 manifest (fingerprint
  `05c04833fcdb`, 20 items/category).

## Fidelity (token-level agreement vs official BF16 release)

Teacher-forced, full-vocabulary KL per token, assistant-turn tokens, held-out
sequences (55,535 scored for the 5.41 pack):

| Suite | Context | Assistant-turn tokens | KL vs official BF16 (mean) | KL (`p50`) | Top-1 Agreement | Top-5 Agreement | Top-5 Overlap |
|---|---|---|---|---|---|---|---|
| Overall ([5.41bpw pack](https://huggingface.co/vcruz305/Ripple-65B-Preview-SAGE-REXL3-5.41bpw)) | — | 55,535 | **0.0005** | 0.000004 | **99.34%** | 99.998% | 95.63% |
| **wiki1100** | 1,100-token prefix | 890 | 0.001269 | 0.000467 | 98.54% | 100% | 97.64% |
| **long17k** | 17,408-token long context | 10,654 | 0.001272 | 0.000438 | 98.70% | 100% | 97.19% |
| [Official BF16 release (`ricursiveAI/Ripple-65B-Preview`)](https://huggingface.co/ricursiveAI/Ripple-65B-Preview) | native | — | 0 | 0 | 100% | 100% | 100% |
