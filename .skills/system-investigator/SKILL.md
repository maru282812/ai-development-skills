---
name: system-investigator
allowed-tools: Read, Grep, Glob, Bash
description: >-
  Next.js(フロントエンド/APIルート/Server Actions) + Supabase(DB/RLS/Functions)
  構成の既存システムを対象に、機能・項目・カラム・APIの使用箇所、影響範囲、
  改修候補箇所を特定する調査スキル。コードベースに対する調査・影響分析の依頼では
  必ずこのスキルを使用する。トリガー例:
  「この項目(カラム/機能)は使われてる?」「どこを直せばいい?」「改修箇所を特定して」
  「〇〇を変更したら影響範囲は?」「影響範囲を調べて」「検索キーワードは?」
  「検索キーワードを洗い出して」「このAPIの呼び出し元は?」「このテーブルはどこから参照されてる?」
  「関連ファイルを探して」「この機能の全体像を調査して」。
  既存コードの使用箇所調査・影響範囲分析・改修ポイント特定が少しでも含まれる依頼は
  すべて調査タスクとみなし、このスキルの手順に従うこと。
---

# system-investigator

## Purpose

既存システム(Next.js + Supabase構成)を対象に、機能・項目・APIの使用箇所・影響範囲・改修候補を特定する。

対象スタック:
- **Next.js**: App Router / Pages Router、Route Handler、Server Actions、コンポーネント、状態管理
- **Supabase**: テーブル定義、RLSポリシー、Database Functions/Triggers、Edge Functions、クライアント呼び出し

## When To Use

- 機能/項目/カラムが使われているか調べたい
- 改修・修正の影響範囲を知りたい
- 改修箇所を特定したい
- 検索キーワードの洗い出しが必要

## Procedure

### 1. キーワード抽出

調査対象から検索キーワードを多角的に列挙する。
- 対象の日本語名、英語名
- camelCase / snake_case の表記揺れ(例: `userName` / `user_name`)
- DBカラム名、テーブル名
- TypeScript型名(interface / type)
- APIパス名(例: `/api/users`)
- SupabaseのRPC名(Database Function名)

### 2. 関連ファイル検索

- grep/ripgrep でプロジェクト全体を横断検索する
  - 対象ディレクトリ: `app/` or `pages/`, `components/`, `lib/`, `hooks/`, `types/`, `utils/`, `supabase/` など
- ファイル名・ディレクトリ名にもキーワードが含まれていないか確認する
- ヒットしたファイルは種別(画面/コンポーネント/API/lib/型定義/migration/テスト)に分類する
- Next.js側の探索ポイントは [references/nextjs.md](references/nextjs.md) を参照すること

### 3. DB確認(Supabase)

- migrationファイルからテーブル定義・カラム定義を特定する
- 該当テーブルのRLSポリシーを確認する
- Database Functions / Triggers が該当テーブル・カラムに関与していないか確認する
- 手順の詳細は [references/supabase.md](references/supabase.md) に従うこと

### 4. API/Route Handler確認(Next.js)

- `app/api/` (App Router) または `pages/api/` (Pages Router) 配下のエンドポイントを特定する
- Server Actions の場合は `'use server'` ディレクティブを持つ関数も対象とする
- リクエスト/レスポンスの型定義を確認する(zodスキーマ等のバリデーション定義も含む)

### 5. Supabaseクライアント呼び出し確認

- `supabase.from('table_name').select/insert/update/delete` の呼び出し箇所を検索する
- `supabase.rpc('function_name')` の呼び出し箇所も検索する
- **クライアント側(Client Component)とサーバー側(Server Component / Route Handler / Server Action)を区別して**それぞれ洗い出す
- 手順の詳細は [references/supabase.md](references/supabase.md) に従うこと

### 6. 画面/コンポーネント確認(Next.js)

- ルーティング(ディレクトリ構造)から対象画面を特定する
- 対象データを表示・入力しているコンポーネントを特定する
- Props の受け渡し、状態管理(useState / Zustand / Redux など、プロジェクトで使用しているもの)を追跡する
- 手順の詳細は [references/nextjs.md](references/nextjs.md) に従うこと

### 7. CRUD整理

- 上記で見つかった処理を Create / Read / Update / Delete の観点で表にまとめる
- 各操作がどこで行われているか(Client / Server / Supabase側のFunction・Trigger)を明記する

### 8. 影響範囲整理

- 直接の関連箇所に加え、以下の有無も確認する:
  - Supabase Edge Functions
  - cronジョブ(`pg_cron`、Vercel Cron、GitHub Actions等)
  - 外部連携(Webhook、Database Webhooks、外部API呼び出し)
- 削除・変更した場合に壊れる可能性のある箇所をリストアップする

## Output

以下のテンプレートで出力する。**ファイルパス・行番号を明記すること。**

```
# 調査結果

## 概要
(調査対象と調査目的のサマリ)

## 検索キーワード
- ...

## 関連ファイル
| 種別 | パス | 概要 |
|---|---|---|

## 関連テーブル(Supabase)
| テーブル | カラム | 用途 | RLS |
|---|---|---|---|

## 関連API/Server Actions(Next.js)
| メソッド | パス/関数名 | 種別(Route Handler/Server Action) | 関連ファイル |
|---|---|---|---|

## 関連画面・コンポーネント(Next.js)
| 画面/コンポーネント | パス | 概要 |
|---|---|---|

## CRUD整理
| 操作 | 場所(Client/Server/Supabase) | 備考 |
|---|---|---|

## 影響範囲
- ...

## 改修候補
- ...

## 注意点
- 不明点・要確認事項
- 推測に基づく箇所(検証推奨)
```

調査結果のサンプルは [examples/](examples/) に配置する。
