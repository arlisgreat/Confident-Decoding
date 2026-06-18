# Examples

Minimal scripts demonstrating how to launch a vLLM server with Confident Decoding and send requests to it.

## Files

- **`serve_confident_decoding.sh`** — Launch vLLM with the default `trough` selection strategy (`p=1.0`).
- **`serve_baseline.sh`** — Launch vLLM with Confident Decoding configured to fall back to standard final-layer decoding (`p=0.0`). Useful for regression tests: outputs should match an unmodified vLLM run.
- **`client_chat.py`** — Minimal Python client that hits the OpenAI-compatible endpoint exposed by vLLM.

## Quick walkthrough

In one terminal:

```bash
bash examples/serve_confident_decoding.sh Qwen/Qwen3.5-9B
```

In another:

```bash
python examples/client_chat.py --model Qwen/Qwen3.5-9B \
    --prompt "What is the capital of France?"
```

## Trying other selection strategies

Edit the `--additional-config` JSON in `serve_confident_decoding.sh`:

```json
{
  "enable_multi_layer_entropy_selection": true,
  "select_method": "last-m8",
  "p": 1.0
}
```

See the top-level `README.md` for the full list of supported `select_method` values and configuration options.
