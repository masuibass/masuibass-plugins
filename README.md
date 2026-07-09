# masuibass-plugins

個人用 Claude Code プラグインのマーケットプレイス(`claude-` で始まる名前は公式予約のためマーケットプレイス名に使用不可)。

## 含まれるプラグイン

### delegation-agents

トークン効率のためのサブエージェント委譲構成(8エージェント)。

| エージェント | モデル | 役割 |
|---|---|---|
| `code-explorer` | Sonnet | コードベース調査(読み取り専用) |
| `web-researcher` | Haiku | 狭い問いに分解済みのWeb調査 |
| `implementer` | Sonnet | 仕様確定済みの実装・編集 |
| `verifier` | Sonnet | テスト・ビルド・型チェックの実行とログ要約 |
| `code-reviewer` | Sonnet | 実装直後の一次レビュー(独立文脈) |
| `deep-reviewer` | Fable 5 | 重要な変更の精密な敵対的レビュー |
| `doc-writer` | Sonnet | 方針確定済みのドキュメント執筆 |
| `simple-tasks` | Haiku | 判断の余地がない機械的作業 |

### youtube-tools

YouTube 関連のスキル集。

| スキル | 内容 |
|---|---|
| `youtube-summary` | yt-dlp で字幕を取得し、サブエージェントで動画の要約・質問回答を行う |

前提: `yt-dlp` がインストールされていること(`brew install yt-dlp`)。

## 新しいマシンでのセットアップ

1. Claude Code でマーケットプレイスを追加してプラグインをインストール:

   ```
   /plugin marketplace add masuibass/masuibass-plugins
   /plugin install delegation-agents@masuibass-plugins
   /plugin install youtube-tools@masuibass-plugins
   ```

2. `~/.claude/CLAUDE.md` に下記の「委譲ポリシー」をコピーする(プラグインでは配布できないため手動。既にある場合は不要)

3. `/model` でメインモデルを設定する(推奨: Fable 5)

注意: `~/.claude/agents/` に同名のエージェント定義を置かないこと。ユーザーレベル定義がプラグイン定義より優先され、プラグインの更新が反映されなくなる。

## 更新の反映

エージェント定義を変更したら、このリポジトリに push した上で各マシンで:

```
/plugin marketplace update masuibass-plugins
```

## ~/.claude/CLAUDE.md に記載する委譲ポリシー

```markdown
# Fundamental Instructions

- 出力は日本語を使用すること
- インタラクションには日本語を使用すること
- Skills, SubAgents の定義にも日本語を使用すること

# サブエージェント委譲ポリシー

トークン効率のため、メインエージェントは判断・設計・ユーザーとの対話・結果の統合に集中し、作業は積極的にサブエージェントへ委譲すること。

- コードベースの調査・複数ファイルの読み込み → `code-explorer` (Sonnet)
- Web調査 → `web-researcher` (Haiku)。広い問いは狭いサブクエスチョンに分解してから並列起動する
- 仕様が確定した実装・編集 → `implementer` (Sonnet)。対象・変更内容・制約・検証方法をプロンプトに含める
- テスト・ビルド・型チェック等の検証 → `verifier` (Sonnet)。長いログをメイン会話に持ち込まない
- 実装直後の一次レビュー → `code-reviewer` (Sonnet)。implementer に実装させたら原則セットで回す
- 重要な変更(リリース前・セキュリティ・複雑なロジック)の精密レビュー → `deep-reviewer` (Fable 5)。コストが高いので要所に絞る
- 方針が固まったドキュメント執筆 → `doc-writer` (Sonnet)
- 判断の余地がない機械的な単純作業、パッケージインストール・環境セットアップの定型実行 → `simple-tasks` (Haiku)

運用ルール:

- 委譲する際は、背景・関連ファイルパス・期待する成果物・完了条件をプロンプトに明示する(サブエージェントはメイン会話の履歴を見られない)
- 独立したタスクは1つのメッセージで複数のサブエージェントを並列起動する。ただし同じファイルを編集しうるタスクは並列に起動しない(編集競合を防ぐ)
- ファイル内容の生ダンプをメイン会話に持ち込まない。サブエージェントからは結論だけを受け取る
- 判断や調査が必要なタスクを Haiku のエージェントに渡さない。迷ったら Sonnet を使う
- 設計判断・要件の解釈・ユーザーへの確認はメインエージェント自身が行い、委譲しない
- 参照先が特定済みの単発のファイル確認・1行の修正など、委譲のオーバーヘッドの方が大きい作業は直接行ってよい
```
