#!/usr/bin/env python3
"""Minimal client example for a vLLM server running with Confident Decoding.

Assumes the server has been launched via examples/serve_confident_decoding.sh
(or equivalent). Sends a single chat completion request and prints the response.

Usage:
    python examples/client_chat.py
    python examples/client_chat.py --model Qwen/Qwen3.5-9B --prompt "Explain entropy"
"""

import argparse
import os

from openai import OpenAI


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--base-url",
        default=os.environ.get("VLLM_BASE_URL", "http://127.0.0.1:8000/v1"),
        help="vLLM OpenAI-compatible base URL",
    )
    parser.add_argument(
        "--api-key",
        default=os.environ.get("VLLM_API_KEY", "token-abc123"),
        help="vLLM API key (use any string if your server does not check)",
    )
    parser.add_argument("--model", default="Qwen/Qwen3.5-9B")
    parser.add_argument(
        "--prompt",
        default="In one paragraph, explain the intuition behind Confident Decoding.",
    )
    parser.add_argument("--max-tokens", type=int, default=512)
    parser.add_argument("--temperature", type=float, default=0.0)
    args = parser.parse_args()

    client = OpenAI(base_url=args.base_url, api_key=args.api_key)
    response = client.chat.completions.create(
        model=args.model,
        messages=[{"role": "user", "content": args.prompt}],
        max_tokens=args.max_tokens,
        temperature=args.temperature,
    )
    print(response.choices[0].message.content)


if __name__ == "__main__":
    main()
