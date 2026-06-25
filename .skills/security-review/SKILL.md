---
name: security-review
allowed-tools: Read, Grep, Glob, Bash
description: >-
  Next.js + Supabase 構成のセキュリティを確認するスキル。RLS・service_role・
  認証認可・個人情報・ログ・Storage policy を対象とする。トリガー例:
  「セキュリティ確認して」「RLS 大丈夫?」「service_role 危なくない?」
  「個人情報大丈夫?」「認可漏れない?」「Supabase の権限確認して」
  「API の認証確認して」「情報漏洩しない?」「他人のデータ見えない?」
  「anon key で何ができる?」。
  情報漏洩・権限・認可の不安、リリース前のセキュリティチェックが
  含まれる依頼ではこのスキルを使用する。
---

# Purpose

Next.js + Supabase 構成のコードベース(または変更差分)を対象に、
情報漏洩・認可漏れにつながる問題を洗い出し、リスク評価と修正指示を出す。

必ず確認する項目:

- RLS(有効化漏れ、操作別ポリシーの不足、条件の誤り)
- service_role の使用箇所(露出リスク、認可チェックの有無)
- anon key の扱い(anon キーで到達できる範囲)
- API 認証(未認証で叩けるエンドポイント)
- API 認可(他人・他テナントのリソースに到達できないか)
- user_id / organization_id / project_id の絞り込み漏れ
- 個人情報(保存・表示・露出の範囲)
- ログに出してはいけない情報(パスワード、トークン、個人情報の生値)
- CSRF / XSS
- Storage bucket policy(公開バケット・パス権限)
- Edge Functions(認証検証、シークレットの扱い)

# バンドルコマンドとの使い分け

Claude Code には汎用の `/security-review`(変更差分のセキュリティ監査・有料プラン)がバンドルされている。
**一般的な脆弱性スキャン(injection / XSS / 依存関係 等)はバンドル `/security-review` を一次窓口にする。**
本スキルは、バンドルでは踏み込みにくい **Supabase 権限モデル固有**——RLS ポリシーの行レベル到達性、
service_role/anon key の到達範囲、テナント横断 IDOR、Storage policy、Edge Functions の JWT 検証——に特化する。
固有依頼で発火させ、汎用依頼はバンドル側に委ねてよい。バンドルが無効な環境では本スキルが fallback になる。

# When To Use

- リリース前・マージ前にセキュリティ観点だけを深く確認したい
- RLS・認可の漏れが不安
- service_role や anon key の使い方が正しいか確認したい
- 個人情報の扱い・ログ出力を点検したい

コード品質全般のレビューは [code-review](../code-review/SKILL.md)、
migration 単体の確認は [migration-review](../migration-review/SKILL.md) を使う。
このスキルは「攻撃者目線でデータに到達できるか」に集中する。

# Procedure

### 1. 対象範囲の確定

- 全体監査か、特定機能・差分かを確認する
- 守るべきデータ(個人情報、課金情報、テナント横断で見えてはいけないもの)を先に列挙する

### 2. RLS 監査

- 全テーブルについて「RLS有効化 × 操作別ポリシー」の表を作る
  (検索手順は [system-investigator の supabase.md](../system-investigator/references/supabase.md) セクション2)
- ポリシー条件を読み、**anon ロール・他テナントのユーザーになったつもりで**到達可能な行を考える
- `security definer` 関数・ビュー(RLSバイパス経路)も確認する

### 3. service_role / キーの監査

- service_role の全使用箇所を検索し、[references/security.md](references/security.md) セクション2の条件と照合する
- `NEXT_PUBLIC_` 環境変数にシークレットが入っていないか、Client Component への漏出経路がないかを確認する

### 4. API 認証・認可の監査

- 全 Route Handler / Server Actions を列挙し、認証チェック(getUser)と認可チェック(所有者・テナント絞り込み)の有無を表にする
- middleware 依存の認証は、素通りするパス(matcher 漏れ)がないか確認する
- IDOR(URLやbodyのIDを差し替えて他人のリソースに到達)の可能性を重点確認する

### 5. 個人情報・ログの監査

- 個人情報を持つテーブル・画面・APIレスポンスを列挙し、必要以上に返していないか(select * で全カラム返却等)を確認する
- `console.log` / ロガーへの出力にトークン・パスワード・個人情報の生値がないか検索する

### 6. その他の経路

- Storage: バケットの public 設定と storage policy、署名付きURLの期限
- XSS: `dangerouslySetInnerHTML`、ユーザー入力のHTML出力
- CSRF: Route Handler の状態変更系 GET、外部から POST されうるエンドポイント
- Edge Functions: JWT 検証の有無(`verify_jwt`)、シークレットのハードコード

### 7. リスク評価と報告

- 発見事項を「重大(即修正)/ 高 / 中 / 低」に分類し、攻撃シナリオ(誰が・どうやって・何を取れるか)を付けて報告する
- 修正指示文を作成する

# Output Template

```md
# セキュリティレビュー: <対象>

## セキュリティ判定
**問題なし / 要修正 / リリース不可** — (要約)

## 重大リスク
| # | 箇所 | 内容 | 攻撃シナリオ |
|---|---|---|---|

## RLS / Policy
| テーブル | RLS | select | insert | update | delete | 問題 |
|---|---|---|---|---|---|---|

## service_role確認
| 箇所 | 用途 | 認可チェック | 判定 |
|---|---|---|---|

## API認証・認可
| エンドポイント | 認証 | 認可(絞り込み) | 問題 |
|---|---|---|---|

## 個人情報・ログ
- (保存・表示・ログ出力の問題点)

## 修正指示
(優先度順。そのままAIエージェントに渡せる形で)
```

実例は [examples/](examples/README.md) を参照。
