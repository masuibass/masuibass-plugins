#!/bin/bash
# Claude Code WorktreeCreate hook.
# Zed の git.worktree_directory(既定 ../worktrees)と同じ場所に worktree を作り、
# Zed の worktree picker から切替・レビューできるようにする。
# stdin: {"name": "...", "cwd": "...", ...}  stdout の最終行: 作成した worktree の絶対パス
set -euo pipefail

input=$(cat)
name=$(printf '%s' "$input" | jq -r '.name')
cwd=$(printf '%s' "$input" | jq -r '.cwd')

root=$(git -C "$cwd" rev-parse --show-toplevel)
# linked worktree 内から呼ばれた場合も main checkout 基準にする
common=$(git -C "$root" rev-parse --path-format=absolute --git-common-dir)
main_root=$(dirname "$common")
repo=$(basename "$main_root")
dir="$(dirname "$main_root")/worktrees/$repo/$name"
# ブランチ名は worktree 名そのまま(push / PR にそのまま使える)
branch="$name"

if [ -e "$dir" ]; then
  echo "worktree-create: $dir already exists" >&2
  exit 1
fi
mkdir -p "$(dirname "$dir")"
if git -C "$root" show-ref --verify --quiet "refs/heads/$branch"; then
  # 同名ブランチが既にあればそれをチェックアウト(他の worktree で使用中なら git がエラーにする)
  git -C "$root" worktree add "$dir" "$branch" >&2
else
  # 現在の HEAD から新規ブランチを切る(worktree.baseRef=head 相当)
  git -C "$root" worktree add -b "$branch" "$dir" HEAD >&2
fi

# .worktreeinclude はフック使用時に処理されないので、ここで gitignore 対象の設定ファイルを写す
if [ -f "$main_root/.worktreeinclude" ]; then
  while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    case "$pat" in \#*) continue;; esac
    (cd "$main_root" && for f in $pat; do
      [ -f "$f" ] && mkdir -p "$dir/$(dirname "$f")" && cp "$f" "$dir/$f"
    done) || true
  done < "$main_root/.worktreeinclude"
fi

echo "$dir"
