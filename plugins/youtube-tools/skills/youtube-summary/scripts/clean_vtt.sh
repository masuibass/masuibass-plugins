#!/bin/bash
# VTT 字幕ファイルからタグ・タイムスタンプ・重複行を除去してプレーンテキストにする
# 使い方: clean_vtt.sh <input.vtt> <output.txt>
set -euo pipefail
sed -E 's/<[^>]*>//g' "$1" \
  | grep -vE '^(WEBVTT|Kind:|Language:|[0-9]{2}:|$)' \
  | awk '!seen[$0]++' > "$2"
