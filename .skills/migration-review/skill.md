---
name: migration-review
description: >-
  Supabase migration (SQL) を本番適用前に確認し、既存データ破壊・RLS漏れ・
  rollback 可否を判定するスキル。トリガー例:
  「migration 確認して」「SQL 確認して」「Supabase migration 大丈夫?」
  「RLS が足りてる?」「policy 足りてる?」「既存データ壊れない?」
  「rollback できる?」「本番適用して大丈夫?」「この ALTER TABLE 危なくない?」
  「migration レビューして」。
  migration ファイル・DDL・RLSポリシーSQLの安全確認が含まれる依頼では
  このスキルを使用する。
---

# Purpose

Supabase migration を適用前にレビューし、「適用可 / 修正必要 / 適用不可」を判定する。

必ず確認する項目:

- 既存データの破壊(DROP / 型変更 / TRUNCATE)
- NOT NULL 追加の危険(既存行に NULL がある場合の失敗)
- default の有無(NOT NULL 追加・新規カラムでの既存行の扱い)
- enum / check 制約(既存データが制約に違反しないか)
- index 作成(ロックの影響)
- RLS policy(新規テーブルの有効化漏れ、操作別ポリシーの不足)
- service_role 前提の処理(RLSなしで運用するつもりのテーブルがないか)
- rollback 可否(失敗時に戻せるか)
- 本番適用順序(コードデプロイとの前後関係)

# When To Use

- 作成した migration を本番・ステージングに適用する前
- AIエージェントが生成した migration SQL の妥当性を確認したい
- RLS ポリシーが十分か確認したい
- 既存データへの影響や rollback 手段を確認したい

これから設計する段階なら [db-designer](../db-designer/skill.md)、
RLS を含むアプリ全体のセキュリティ確認は [security-review](../security-review/skill.md) を使う。

# Procedure

### 1. 対象 migration の特定

- `supabase/migrations/` の未適用ファイル(または指定されたファイル)を読む
- 複数ファイルある場合は timestamp 順に、適用順序どおりに確認する

### 2. 既存スキーマ・既存データとの突き合わせ

- 対象テーブルの現在の定義を過去 migration から把握する
  (手順は [system-investigator の supabase.md](../system-investigator/references/supabase.md) セクション1)
- 既存データの状態に依存する操作(NOT NULL追加、制約追加、型変更)を洗い出す

### 3. 危険操作のチェック

- [references/migration-safety.md](references/migration-safety.md) の危険操作一覧と照合する
- 各 SQL 文について「既存行があった場合に何が起きるか」を考える

### 4. RLS の確認

- `create table` に対応する `enable row level security` があるか
- 操作別(select / insert / update / delete)のポリシーが要件どおり揃っているか
- カラム追加・仕様変更が既存ポリシーの条件と矛盾しないか
- 「service_role からしか触らないので RLS 不要」という前提のテーブルは、その前提をコード側で確認し、それでも RLS 有効化(ポリシーなし)を推奨する

### 5. アプリコードとの整合確認

- migration で変えるテーブル・カラムを使っているコードを検索し、デプロイ順序の問題(旧コード × 新スキーマ、新コード × 旧スキーマ)を確認する
- 削除・rename はコード側の移行が済んでいるかを必ず確認する

### 6. rollback 方針の確認

- 逆方向の SQL(down migration)が書けるか、書けない操作(データ削除を伴うもの)はバックアップ手段があるか
- 戻せない操作を含む場合は、expand-contract(段階的移行)への分割を提案する

### 7. 判定と報告

- 「適用可 / 修正必要 / 適用不可」を判定し、修正が必要な場合は修正 SQL 案を提示する

# Output Template

```md
# Migration レビュー: <ファイル名>

## 判定
**適用可 / 修正必要 / 適用不可** — (理由を1〜2文)

## 危険箇所
| # | 行/SQL | 問題 | 影響 |
|---|---|---|---|

## RLS確認
| テーブル | RLS有効化 | select | insert | update | delete | 備考 |
|---|---|---|---|---|---|---|

## 既存データ影響
- (既存行・既存コードへの影響)

## rollback方針
- (逆SQL案、または戻せない操作とその代替手段)

## 修正SQL案
```sql
```

## 本番適用前チェック
- [ ] ステージング(またはローカル db reset)で適用確認済み
- [ ] 既存データに制約違反がないことを SELECT で確認済み
- [ ] コードデプロイとの順序を確認済み
- [ ] バックアップ取得済み(戻せない操作を含む場合)
```

実例は [examples/](examples/README.md) を参照。
