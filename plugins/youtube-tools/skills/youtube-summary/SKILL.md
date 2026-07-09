---
name: youtube-summary
description: YouTube 動画の URL から字幕(トランスクリプト)を取得し、内容の要約や質問への回答を行う。ユーザーが YouTube の URL を渡して「この動画を要約して」「動画の内容を教えて」「この動画について質問したい」と言った時に使う。動画ファイル自体のダウンロードには使わない。
---

# YouTube 動画の内容読み込み・要約

yt-dlp で YouTube 動画の字幕を取得し、その内容をもとに要約・質問回答を行うスキル。

## 手順

1. **引数の確認**: YouTube の URL(`https://www.youtube.com/watch?v=...` または `https://youtu.be/...`)を受け取る。URL がなければユーザーに尋ねる。

2. **作業ディレクトリ**: 字幕ファイルはスクラッチパッドディレクトリ(なければ `/tmp`)に保存する。ユーザーのプロジェクトに字幕ファイルを残さない。

3. **メタデータと字幕の取得**:

   ```bash
   cd <作業ディレクトリ>
   yt-dlp --skip-download \
     --write-subs --write-auto-subs \
     --sub-langs "ja,en" --sub-format "vtt" \
     --print-to-file "%(title)s\n%(uploader)s\n%(duration_string)s\n%(upload_date)s" meta.txt \
     -o "sub" "<URL>"
   ```

   - 手動字幕(`--write-subs`)を優先し、なければ自動生成字幕(`--write-auto-subs`)を使う
   - 日本語字幕を優先、なければ英語字幕を使う
   - 出力例: `sub.ja.vtt`, `sub.en.vtt` など

4. **字幕が取得できない場合**:
   - `--list-subs "<URL>"` で利用可能な字幕言語を確認し、あった言語で再取得する
   - 字幕が一切ない場合はその旨をユーザーに伝え、対応を確認する(音声の文字起こしは時間がかかるため勝手に始めない)

5. **VTT の整形**: VTT ファイルはタイムスタンプ・重複行・タグを含むため、このスキルの `scripts/clean_vtt.sh` で整形してから読む:

   ```bash
   bash <このスキルのディレクトリ>/scripts/clean_vtt.sh sub.ja.vtt transcript.txt
   ```

6. **サブエージェントによる要約**: `transcript.txt` をメイン会話で直接読まず、サブエージェント(Agent ツール、subagent_type: `general-purpose`、model: `sonnet`)に読ませて要点を受け取る。プロンプトには以下を必ず含める:
   - `transcript.txt` の絶対パスと、`meta.txt`(タイトル・チャンネル名等)の絶対パス
   - 自動生成字幕なので誤認識や句読点の欠落がある旨
   - 期待する成果物: 動画の主題、要点(箇条書き)、重要な固有名詞・ツール名・手順、結論。ユーザーからの質問がある場合はその質問への回答
   - 出力は日本語で書くこと

7. **回答**: サブエージェントの結果をもとに、動画タイトル・チャンネル名・長さを冒頭に示した上で、要約または質問への回答を日本語で提示する。

## 注意事項

- 動画本体はダウンロードしない(`--skip-download` を必ず付ける)
- 自動生成字幕は誤認識を含むため、固有名詞などが不自然な場合はその旨を断る
- 著作権・利用規約の範囲内での利用(内容把握・要約)に限る
- 取得に失敗した場合、yt-dlp のバージョンが古い可能性がある(`brew upgrade yt-dlp` を提案する)
