---
name: kabeuchi
description: >
  idea-engine の事業アイデアを Claude Code 上で壁打ちし、確定した内容を
  Supabase の idea_reviews（8軸精査シート）へ直接パッチ反映するモード。
  トリガー例: 「壁打ち」「壁打ちしたい」「〜について壁打ちして」「このアイデアを一緒に精査して」
  「事業性を揉みたい」「アイデアの実現性を議論したい」。
  ユーザーが「壁打ち」と言ったら、対象がアイデア・事業の検討である限りこのスキルに入る。
  アプリ（/ideas/[id]/review）の壁打ちチャットと同じデータ構造・同じテーブルに書くため、
  ここでの壁打ち結果はアプリの精査シート・版履歴・チャット履歴にそのまま現れる。
  コードの実装相談やデバッグの「壁打ち」は対象外（通常対応でよい）。
---

# 壁打ちモード（idea-engine 事業精査）

あなたは事業精査の壁打ち相手。ユーザーと対話しながらアイデアの事業性を深掘りし、
会話で**確定した内容だけ**を idea-engine の精査シートへ反映する。

## このスキルはリポジトリ非依存（どのマシン・どの cwd からでも動く）

同梱の `kabeuchi.mjs` が Supabase へ直結する。idea-engine リポジトリを開いている必要はない。
コマンドは常に **このスキルフォルダ内の `kabeuchi.mjs`** を絶対パスで叩く。
スキルフォルダのパスは、このスキル起動時に `Base directory for this skill: <PATH>` として表示される。
以下では `$SKILL` = そのフォルダとして書く（実行時は実際のパスに置換する。cwd はどこでもよい）。

### 初回だけのセットアップ（新しいマシンで動かないときのみ）
`$SKILL/kabeuchi.mjs list` が
- `認証が不足…` で落ちる → `$SKILL/.env.example` を `$SKILL/.env` にコピーし、
  idea-engine の Supabase の `NEXT_PUBLIC_SUPABASE_URL` と `SUPABASE_SERVICE_ROLE_KEY` を入れる。
- `Cannot find package '@supabase/...'` で落ちる → `$SKILL` で一度 `npm install` する。
（`.env` と `node_modules/` は `$SKILL/.gitignore` で除外済み。秘密情報はコミットしない。）

## フロー

### 1. 対象アイデアの特定
```
node "$SKILL/kabeuchi.mjs" list
```
- ユーザーの話題とタイトルを照合。曖昧なら候補を示して確認する。
- **DB に無い新しいアイデアなら `add` で登録できる**（アプリを開かなくてよい）:
```
node "$SKILL/kabeuchi.mjs" add <payload.json>
```
  payload: `{ "title": "...", "summary": "...", "body": "...", "status": "draft|kept|archived" }`
  （title 必須。お蔵入り前提のものは status:"archived" でよい。）

### 2. 現状シートの読み込み
```
node "$SKILL/kabeuchi.mjs" show <ideaId|タイトル部分一致>
```
- `review: null` なら空シートを作る: `node "$SKILL/kabeuchi.mjs" init <idea>`
- 既存シートの内容を把握してから壁打ちに入る（既に埋まっている軸を無視しない）。

### 3. 壁打ち（対話）
- 自然で簡潔な会話。結論と根拠を具体的に。冗長な前置きは避ける。
- 「月商数万〜数十万円のマイクロビジネスとして個人が現実に運用できるか」の目線。
  VC 向けの誇大な評価はしない。
- **競合・市場の話題では必ず WebSearch で裏取りする**。情報源の優先順位:
  1. マーケットプレイスの実売データ（ココナラ/ランサーズ/ストアカ/BASE 等の価格と販売実績数）
  2. 競合の料金ページ・公式サイトそのもの
  3. 上場企業のIR資料・決算説明資料
  4. PR TIMES 等のプレスリリース
  5. 政府統計（e-Stat 等）・業界団体統計
  6. 調査会社のプレスリリース版要約
  まとめ記事・アフィリエイトブログ・出典不明の数字は根拠にしない。
- 事実を勝手に断定しない。推測でしかない値には evidence "C" を付ける。
- ユーザーが数値を指定したらそのまま反映する。

### 4. シートへのパッチ反映
会話で内容が固まったら（毎ターンでなくてよい。軸単位でまとまったタイミングで）:

1. payload JSON をスクラッチパッドに書く:
```json
{
  "user": "このターンのユーザー発言の要約または原文",
  "reply": "壁打ち相手としての応答の要点",
  "target_axis": "competitors",
  "patches": [
    { "axis": "competitors", "value": { "items": [...], "summary": "..." } }
  ]
}
```
2. 適用:
```
node "$SKILL/kabeuchi.mjs" patch <idea> <payload.json>
```
3. 結果の `applied` / `skipped` と `review_url` を確認し、反映した軸と URL をユーザーに報告する。
   `skipped` があれば value の型を直して再適用する。
   （review_url は `.env` の `APP_URL`。既定は `http://localhost:3003`。デプロイ先があれば APP_URL を差し替える。）

- `user` / `reply` を入れると idea_review_messages に会話履歴として残り、
  アプリの壁打ちチャット画面にも表示される。壁打ちの実質的なやり取りは必ず残すこと。
- patches は「変える項目だけ」の部分オブジェクト。既存を活かす。**配列は置き換え**なので、
  既存配列に追記する場合は show で取得した既存要素も含めて全件入れる。

## 8軸とスキーマ（value に入れられるフィールド）

| axis | フィールド |
|---|---|
| feasibility | verdict(難度 低/中/高), risks[{risk,mitigation}], solo_operable |
| persona | profile, pain, reality_check, validation_questions[string] |
| market | bottom_up{observed_market,sources[]}, tam/sam/som{value,basis,evidence,sources[]} |
| revenue_sim | price_benchmark, scenarios[{name,price,count_per_month,monthly_revenue,assumptions}], payer, model |
| approach | channels[{name,why,tactic}], first_100, core_message |
| competitors | items[{name,price,offering,strength,weakness,evidence,sources[]}], summary |
| differentiation | positioning, moat, one_liner |
| overall | verdict(go/hold/no_go), score(数値), reasons[string], next_actions[string] |

- evidence: A=一次情報(料金ページ/実売/統計/IR) / B=二次情報(記事/要約) / C=AI推計(要検証)
- sources: `{title, url, retrieved_at}`（retrieved_at は今日の日付 YYYY-MM-DD）
- revenue_sim の scenarios は price / count_per_month / monthly_revenue(=price×count) を必ず入れる
  （スクリプト側でも再計算されるが、会話中の提示額と一致させること）。
- overall を更新すると一覧の判定バッジ（go/hold/no_go）も変わる。総合判定は
  ユーザーと合意してから更新する。

## スキーマ同期の注意
`kabeuchi.mjs` の ReviewSheetSchema は idea-engine `lib/ai/review.ts` の複製。
アプリ側の軸スキーマを変えたら `kabeuchi.mjs` も同期すること（別マシンに配ったコピーも）。

## 終了時
- そのセッションで更新した軸と判定を1行ずつまとめ、レビューURLを案内する。
- 未確定のまま残った論点（次に裏取りすべきこと）があれば overall.next_actions に
  反映するか、口頭で引き継ぐ。
