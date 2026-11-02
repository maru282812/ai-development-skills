#!/usr/bin/env bash
# eval-kit ランナー（macOS / Linux / Git Bash）
# 使い方:  ./scripts/run.sh
# 事前に環境変数 ANTHROPIC_API_KEY を設定しておくこと（被験・Judge両方が使う）。
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "WARN: ANTHROPIC_API_KEY が未設定です。モデル呼び出しに失敗します。" >&2
fi

mkdir -p results
npx --yes promptfoo@latest eval -c promptfooconfig.yaml --output results/latest.json
echo
echo "結果をブラウザで見る: npx promptfoo@latest view"
