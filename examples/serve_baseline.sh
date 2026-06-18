#!/usr/bin/env bash
# Launch a vLLM server with Confident Decoding configured to behave equivalent
# to standard final-layer decoding (p=0.0). Useful for regression-testing the
# integration: outputs should match an unmodified vLLM run.
#
# Usage: bash examples/serve_baseline.sh [MODEL_PATH]

set -euo pipefail

MODEL="${1:-Qwen/Qwen3.5-9B}"
PORT="${PORT:-8000}"
TP_SIZE="${TP_SIZE:-1}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-32768}"

vllm serve "$MODEL" \
  --port "$PORT" \
  --tensor-parallel-size "$TP_SIZE" \
  --max-model-len "$MAX_MODEL_LEN" \
  --additional-config '{
    "enable_multi_layer_entropy_selection": true,
    "select_method": "trough",
    "p": 0.0
  }'
