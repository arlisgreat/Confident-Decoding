# Confident Decoding

An inference-time logits-layer selection method for autoregressive language models. Instead of always using the logits from the final transformer layer, Confident Decoding searches among a set of near-final candidate layers and selects the one where the model's prediction is most confident (lowest entropy). The default `trough` strategy scans prediction entropy from the back to the front and selects the first entropy valley closest to the final layer.

This repository provides a fork of [vLLM](https://github.com/vllm-project/vllm) (v0.19.1) with Confident Decoding integrated, plus a benchmark evaluation harness.

## Quick Start

### Serving a model with Confident Decoding

```bash
# Install vLLM v0.19.1, then overlay our modified source files
pip install vllm==0.19.1
VLLM_PKG=$(python -c "import vllm, os; print(os.path.dirname(vllm.__file__))")
cp -r confident-vllm/* "$VLLM_PKG"/

# Run with trough decoding enabled
vllm serve Qwen/Qwen3.5-9B \
  --port 8000 \
  --tensor-parallel-size 1 \
  --max-model-len 32768 \
  --additional-config '{
    "enable_multi_layer_entropy_selection": true,
    "select_method": "trough",
    "p": 1.0,
    "trough_max_backtrack_layers": 10
  }'
```

### Configuration options

| Parameter | Type | Default | Description |
|---|---|---|---|
| `enable_multi_layer_entropy_selection` | bool | `false` | Enable Confident Decoding |
| `select_method` | str | `"trough"` | Layer selection strategy (see below) |
| `p` | float | `1.0` | Probability of using selected-layer logits |
| `trough_max_backtrack_layers` | int | `0` | Max layers to backtrack from the final layer |
| `trough_backtrack_ratio` | float | `0.0` | Backtrack window as fraction of total layers |
| `trough_log_interval` | int | `0` | Log interval for selection statistics (0 = off) |

### Selection strategies

| Method | Description |
|---|---|
| `trough` | Default. First entropy valley from the final layer backward. |
| `trough-m1` / `trough-m2` | Shift `trough` selection 1–2 layers shallower. |
| `trough-p1` / `trough-p2` | Shift `trough` selection 1–2 layers deeper. |
| `last-m1` / `last-m2` / `last-m4` / `last-m8` | Fixed offset from the final layer (no entropy computation). |

### Regression test: verify standard decoding equivalence

```bash
# Run with p=0 to fall back to standard final-layer decoding
vllm serve Qwen/Qwen3.5-9B \
  --port 8000 \
  --additional-config '{
    "enable_multi_layer_entropy_selection": true,
    "select_method": "trough",
    "p": 0.0
  }'
```

## Supported Models

The following model families are supported. For multimodal models, Confident Decoding is active when using the language-model entry point (`*ForCausalLM`) or specific multimodal wrappers (`*ForConditionalGeneration`) that dispatch through the language model.

**Llama family:** Llama, Llama4, Mistral, Mixtral

**Qwen family:** Qwen2, Qwen3, Qwen2 MoE, Qwen3 MoE, Qwen3 Next, Qwen3.5 (text & multimodal), Qwen2-VL, Qwen2.5-VL

**Gemma family:** Gemma2, Gemma3 (text & multimodal), Gemma4 (text & multimodal)

**Others:** DeepSeek-V2 / GLM family, GPT-OSS

## Project Structure

```
.
├── confident-vllm/          # Modified vLLM source files (overlay onto pip-installed vllm)
│   ├── CONFIDENT_DECODING.md  # Technical documentation
│   ├── model_executor/models/trough_utils.py  # Core entropy/trough logic
│   └── model_executor/models/*.py  # Model integrations
└── eval/                   # Evaluation harness
    ├── config/             # model2path.json, model2maxlen.json
    ├── sh/                 # run_all_benchmarks_vllm_openai.sh
    ├── gpqa/               # GPQA-Diamond benchmark
    ├── hle/                # HLE benchmark
    ├── LiveCodeBench/      # LiveCodeBench v6
    ├── LongBench/          # LongBench
    ├── omni-math-rule/     # Omni-Math-Rule
    └── air-bench-2024/     # AirBench
```

## Running Benchmarks

Edit `eval/config/model2path.json` and `eval/config/model2maxlen.json` to point to your model checkpoints, then:

```bash
cd eval
bash sh/run_all_benchmarks_vllm_openai.sh <model_key> [benchmarks_csv]

# Examples:
bash sh/run_all_benchmarks_vllm_openai.sh Qwen3.5-9B all
bash sh/run_all_benchmarks_vllm_openai.sh Qwen3.5-9B gpqa,lcb
bash sh/run_all_benchmarks_vllm_openai.sh Qwen3.5-9B hle,longbench,omni,airbench
```

Set `VLLM_BASE_URL` and `VLLM_API_KEY` to point to your running vLLM server. Available benchmarks: `gpqa`, `hle`, `lcb`, `longbench`, `omni`, `airbench`.

## Technical Details

Confident Decoding works by capturing hidden states from the last `N` candidate layers during the model forward pass. The final normalization (`ln_f`) is applied to each candidate state, and logits are computed for all candidates via a single batched `lm_head` call. Per-token prediction entropy is computed, and the `trough` strategy scans backward from the final layer to find the first local entropy minimum. The logits from the selected layer are used for decoding.

See [confident-vllm/CONFIDENT_DECODING.md](confident-vllm/CONFIDENT_DECODING.md) for the full technical documentation.

## Requirements

- Python 3.10+
- CUDA 12.1+ (for GPU inference)
- PyTorch 2.x

Install [vLLM](https://github.com/vllm-project/vllm) v0.19.1 first (`pip install vllm==0.19.1`), then copy the contents of `confident-vllm/` into the installed `vllm` package directory (see Quick Start). The `confident-vllm/` directory contains the modified vLLM source files only — it is not a standalone installable package. Each benchmark in `eval/` has its own dependencies — see each subdirectory for details (e.g. `eval/LongBench/requirements.txt`).

## License

The `confident-vllm/` directory is derived from [vLLM](https://github.com/vllm-project/vllm) and inherits its Apache 2.0 license. Modifications introduced for Confident Decoding are released under the same terms. Benchmark code under `eval/` is derived from the respective upstream benchmark repositories and inherits their licenses.

## Citation

We now have a paper you can cite:

```bibtex
@article{confident decoding,
  title={Deeper is Not Always Better: Mitigating the Alignment Tax via Confident Layer Decoding},
  author={Zhang, Xuanming and Zhoubian, Sining and Chen, Yuxuan and Tang, Tianyi and Yang, An and Du, Sean and Zheng, Chujie and Huang, Fei and Liu, Dayiheng and Huang, Gao and Zhou, Jingren},
  journal={arXiv preprint arXiv:2606.21906},
  year={2026}
}
```
