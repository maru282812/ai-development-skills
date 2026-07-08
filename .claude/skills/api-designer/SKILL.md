---
name: api-designer
allowed-tools: Read, Write, Edit, Grep, Glob
metadata:
  reasoning-tier: deep
  summary: "API設計担当。Next.js の Route Handler / Server Actions 前提で、エンドポイント・request/response・認証認可・エラー設計をまとめる。"
description: >-
  Next.js の Route Handler / Server Actions 前提で、エンドポイント・
  request/response・認証認可・エラー設計を含む API 設計を行うスキル。
  トリガー例:
  「API設計して」「エンドポイント考えて」「route handler 作って」
  「request / response 考えて」「API仕様書を作って」
  「Server Actions にするか API にするか」「認可チェックどこでやる?」
  「APIのインターフェース決めて」「レスポンス形式どうする?」。
  APIの新規設計・既存APIの拡張検討・API仕様書作成が含まれる依頼では
  このスキルを使用する。
---

# Purpose

Next.js + Supabase 構成で、実装に直結する API 設計(仕様書)を作成する。

必ず扱う項目:

- endpoint(パス設計、Route Handler / Server Actions の選択)
- method(GET / POST / PUT / PATCH / DELETE)
- request(パラメータ、body、型)
- response(成功時の形、ステータスコード)
- validation(zod 等での検証内容)
- authentication(誰がログイン済みである必要があるか)
- authorization(リソースへの権限チェックをどこで行うか)
- Supabase access(server client / service_role、RLSとの分担)
- error response(エラー形式の統一)
- logging(何を記録し、何を記録してはいけないか)
- rate limit の要否

# When To Use

- 新機能のAPIインターフェースを決めたい
- Server Actions と Route Handler のどちらにすべきか判断したい
- request / response の形と validation を仕様化したい
- 認可チェックの置き場所(API側 / RLS側)を整理したい
- 実装者(またはAIエージェント)に渡すAPI仕様書を作りたい

DB スキーマ自体の設計は [db-designer](../db-designer/SKILL.md)、
実装後の確認は [code-review](../code-review/SKILL.md) / [security-review](../security-review/SKILL.md) を使う。

# Procedure

### 1. 要件の整理

- 誰が(ユーザー種別)、どの画面から、何をするためのAPIかを整理する
- 既存APIの有無・流用可否を確認する(調査は [system-investigator](../system-investigator/SKILL.md))

### 2. Server Actions / Route Handler の選択

- [references/api-design.md](references/api-design.md) セクション1の判断基準で選択する
- 原則: 自アプリのフォーム・UI操作 → Server Actions、外部公開・webhook・他クライアントからの呼び出し → Route Handler

### 3. エンドポイント / 関数の設計

- リソース指向でパス(または action 関数名)を設計し、一覧表にする
- 既存のパス規約・命名規約に合わせる

### 4. Request / Response の設計

- 入出力を TypeScript 型 + zod スキーマで定義する
- エラーレスポンスは [references/api-design.md](references/api-design.md) セクション2の統一形式に従う
- ページネーション・ソート・フィルタが必要な一覧APIはパラメータ仕様を明記する

### 5. 認証・認可の設計

- 各エンドポイントについて「認証要否」「認可条件(所有者・ロール)」「チェック場所(コード / RLS / 両方)」を表にする
- 判断基準は [references/api-design.md](references/api-design.md) セクション3を参照
- service_role を使う場合は、その理由とコード側で行う認可チェックを必ず明記する

### 6. 横断的関心事の設計

- logging: 記録する項目(actor, action, target)と記録してはいけない項目(パスワード、トークン、個人情報の生値)
- rate limit: 認証なしで叩ける・コストの高い・乱用されうるエンドポイントには要否を判断する
- 冪等性: 課金・送信系の POST はリトライ・二重送信への耐性を検討する

### 7. 実装ファイルへの落とし込み

- 各エンドポイントの実装ファイルパス(`app/api/.../route.ts` / `app/actions/...ts`)と、共有するヘルパー(認証取得、エラー整形)を列挙する

# Output Template

```md
# API設計: <機能名>

## API設計概要
(目的、Server Actions / Route Handler の選択と理由)

## エンドポイント一覧
| Method/種別 | パス or 関数名 | 用途 | 認証 | 認可 |
|---|---|---|---|---|

## Request / Response
### <エンドポイント名>
- Request: (型 / zodスキーマ)
- Response 成功時: (型、ステータスコード)
- Response 失敗時: (エラーコードと条件)

## 認証・認可
| エンドポイント | 認証 | 認可条件 | チェック場所(コード/RLS) |
|---|---|---|---|

## Supabaseアクセス方針
- 使用クライアント(server / service_role)と理由
- RLS との役割分担

## エラー設計
(統一エラー形式と、本機能で使うエラーコード一覧)

## 実装ファイル
| パス | 内容 |
|---|---|

## API仕様
(上記をまとめた、実装者にそのまま渡せる仕様。rate limit / logging / 冪等性の方針を含む)
```

実例は [examples/](examples/README.md) を参照。

# 実行モデルティア

推奨ティア: **deep**（判断・設計・監査の質がモデルの推論力に依存する）。
最上位推論クラスのモデルが使えない環境でも中止しない。代わりに劣化運転として、
結論は候補＋根拠＋確信度で提示して1本に絞り込まず、工程を細かく区切って
ユーザー確認を挟み、不可逆な提案（削除・破壊的変更・本番適用）では必ず停止すること。
具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
