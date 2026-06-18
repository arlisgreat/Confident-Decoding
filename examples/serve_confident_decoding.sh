#!/usr/bin/env bash
# Launch a vLLM server with Confident Decoding (trough strategy) enabled.
#
# Usage: bash examples/serve_confident_decoding.sh [MODEL_PATH]
#
# Environment variables:
#   PORT          - server port (default 8000)
#   TP_SIZE       - tensor parallel size (default 1)
#   MAX_MODEL_LEN - max model length (default 32768)

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
    "p": 1.0,
    "trough_max_backtrack_layers": 10,
    "trough_log_interval": 200
  }'
