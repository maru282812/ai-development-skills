---
name: code-review
description: >-
  Next.js + Supabase の実装済みコードを対象に、型・コンポーネント境界・
  認証認可・RLS・バリデーション・エラーハンドリング・既存機能への影響を
  レビューするスキル。トリガー例:
  「レビューして」「問題ないか見て」「バグがないか確認して」「実装漏れは?」
  「設計的に大丈夫?」「このコードでいい?」「build は通るけど不安」
  「セキュリティ的に危ない?」「この実装どう思う?」「直すところある?」。
  実装後のコード確認・品質チェック・実装漏れ確認が含まれる依頼では
  このスキルを使用する。セキュリティ専門の深掘りは security-review を使う。
---

# Purpose

実装後のコードをレビューし、重大な問題・修正推奨・軽微な改善に分類して報告する。
修正が必要な場合は、そのまま AI エージェントに渡せる修正指示文まで作成する。

確認観点:

- TypeScript 型(any の濫用、型アサーション、null安全)
- Next.js App Router / Pages Router の規約準拠
- Server / Client Component の境界(`'use client'` の適切さ、秘密情報の漏出)
- Supabase client / server / service_role クライアントの使い分け
- 認証・認可(ログイン確認、リソースの所有者確認)
- RLS(クライアント直アクセスの行レベル保護)
- API validation(zod 等での入力検証)
- error handling(握りつぶし、ユーザーへの通知、ログ)
- build / lint が通るか
- UI崩れ(レイアウト、レスポンシブ)
- 既存機能への影響(回帰リスク)

# When To Use

- 実装が終わったコード(diff / PR / ブランチ)を確認してほしい
- 「動いているけど不安」な実装の妥当性を見てほしい
- 実装漏れ・考慮漏れがないか確認したい
- マージ前の最終チェックをしたい

セキュリティだけを深く見たい場合は [security-review](../security-review/skill.md)、
migration SQL の確認は [migration-review](../migration-review/skill.md)、
構造の整理が主目的なら [refactor-planner](../refactor-planner/skill.md) を使う。

# Procedure

### 1. レビュー対象の特定

- `git diff` / `git log` で変更ファイルを特定する(PR指定があれば `gh pr diff`)
- 変更の目的(何を実装したのか)を把握する。不明なら commit message・関連issueから推測し、仮定として明示する

### 2. 静的確認

- `npx tsc --noEmit`、`npm run lint`、可能なら `npm run build` を実行する
- 失敗した場合はそれ自体を重大な問題として報告する

### 3. 観点別レビュー

[references/review-checklist.md](references/review-checklist.md) のチェックリストに従い、変更ファイルを観点別に確認する。

特に重点的に見るもの:

- **Server/Client 境界**: `'use client'` ファイルに service_role・秘密の環境変数・サーバ専用処理が混ざっていないか
- **Supabase クライアントの使い分け**: 実行コンテキストに合ったクライアント生成か([system-investigator の nextjs.md セクション3](../system-investigator/references/nextjs.md) 参照)
- **認可**: APIや Server Action の冒頭でユーザー確認・リソース所有者確認をしているか
- **RLS**: クライアント直の `.from()` アクセスに対応するポリシーが存在するか([system-investigator の supabase.md セクション2](../system-investigator/references/supabase.md) 参照)
- **validation**: 外部入力(request body / searchParams / formData)を未検証で使っていないか

### 4. 既存機能への影響確認

- 変更された関数・コンポーネント・テーブルの利用元を検索し、壊れる可能性のある箇所を特定する
- 共有コンポーネント・共通関数の変更は特に注意。利用元すべての挙動を考える

### 5. 分類と報告

- 指摘を「重大な問題(マージ不可)/ 修正推奨 / 軽微な改善」に分類する
- 各指摘に **ファイルパス・行番号・理由・修正方針** を付ける
- 重大な問題と修正推奨には、AIエージェントに渡せる修正指示文を作成する

# Output Template

```md
# レビュー結果: <対象>

## 総評
(マージ可否の判断と全体所感。2〜3文)

## 重大な問題
| # | ファイル:行 | 内容 | 理由 |
|---|---|---|---|

## 修正推奨
| # | ファイル:行 | 内容 | 理由 |
|---|---|---|---|

## 軽微な改善
- (任意対応のもの)

## 影響範囲
- (変更が波及する既存機能・画面・API)

## 確認コマンド
```bash
npx tsc --noEmit
npm run lint
npm run build
```

## 修正指示文
(重大な問題・修正推奨をまとめて、そのままAIエージェントに貼れる形で)
```

実例は [examples/](examples/README.md) を参照。
