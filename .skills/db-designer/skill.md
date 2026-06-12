---
name: db-designer
description: >-
  Supabase (PostgreSQL) 前提で、テーブル・カラム・制約・index・RLS を含む
  DB設計を行い、migration 案まで作成するスキル。トリガー例:
  「テーブル設計して」「DB設計して」「カラムを考えて」「ER図を考えて」
  「Supabase のテーブルを作りたい」「RLS 前提で設計して」
  「どのテーブルに持たせる?」「正規化した方がいい?」「スキーマを考えて」
  「リレーションどうする?」。
  新規テーブル設計・既存スキーマへのカラム追加検討・データモデリングが
  含まれる依頼ではこのスキルを使用する。
---

# Purpose

Supabase (PostgreSQL) を前提に、要件からテーブル設計・RLS方針・migration 案までを作成する。

必ず扱う項目:

- テーブル(命名、責務、既存テーブルとの関係)
- カラム(型、NULL可否、default)
- PK / FK(参照整合性、ON DELETE の挙動)
- index(検索・JOIN・RLS条件で使うカラム)
- unique 制約
- enum / check 制約
- RLS(誰がどの行を読めて・書けるか)
- created_at / updated_at(自動更新の方法)
- 論理削除の要否(deleted_at か物理削除か)
- audit log の要否

# When To Use

- 新機能のためのテーブルを設計したい
- 既存テーブルにカラムを追加すべきか、新テーブルにすべきか迷っている
- 正規化の程度(分けるか持たせるか)を判断したい
- RLS 前提でアクセス制御込みのスキーマを設計したい
- ER図(リレーション図)を整理したい

既存スキーマの調査は [system-investigator](../system-investigator/skill.md)、
作成済み migration SQL の安全確認は [migration-review](../migration-review/skill.md) を使う。

# Procedure

### 1. 要件の整理

- 保存するデータ、誰が読み書きするか(ユーザー種別)、想定データ量・増加ペースを確認する
- マルチテナント要件(organization / project 単位の分離)の有無を必ず確認する

### 2. 既存スキーマの確認

- `supabase/migrations/` と `database.types.ts` から既存テーブルを把握する
  (手順は [system-investigator の supabase.md](../system-investigator/references/supabase.md) セクション1)
- 既存の命名規則(単数/複数、snake_case)、共通カラム(created_at 等)、RLSのパターンを踏襲する

### 3. エンティティとリレーションの設計

- エンティティを抽出し、1対多 / 多対多 / 1対1 を整理する(多対多は中間テーブル)
- 正規化の判断基準は [references/db-design.md](references/db-design.md) セクション1を参照
- ER図は mermaid (`erDiagram`) で表現する

### 4. カラム定義

- 各テーブルのカラムを型・NULL可否・default・制約付きで定義する
- 型の選定・共通カラム・論理削除の判断は [references/db-design.md](references/db-design.md) セクション2を参照

### 5. RLS 設計

- テーブルごとに「誰が・どの操作で・どの行に」アクセスできるかを表にする
- ポリシーのSQL案を書く。パターン集は [references/db-design.md](references/db-design.md) セクション3を参照
- service_role 前提(クライアント直アクセスなし)のテーブルでも RLS は有効化する

### 6. Index / 制約の設計

- FKカラム、RLS条件で使うカラム、検索・ソートに使うカラムに index を検討する
- unique 制約・check 制約でデータ不変条件をDBレベルで保証する

### 7. migration 案の作成

- CREATE TABLE / index / RLS有効化 / ポリシーまで含む SQL を1ファイル分作成する
- 既存テーブルへの変更を含む場合は [migration-review](../migration-review/skill.md) の観点(NOT NULL追加の危険等)を事前に織り込む

# Output Template

```md
# DB設計: <機能名>

## DB設計方針
(設計判断の要約: 正規化の程度、マルチテナント分離、論理削除・audit log の要否と理由)

## テーブル一覧
| テーブル | 責務 | 新規/既存変更 |
|---|---|---|

## カラム定義
### <table_name>
| カラム | 型 | NULL | default | 制約 | 説明 |
|---|---|---|---|---|---|

## リレーション
```mermaid
erDiagram
```

## RLS方針
| テーブル | 操作 | 対象者 | 条件 |
|---|---|---|---|

## Index / Constraint
| テーブル | 種別 | 対象カラム | 理由 |
|---|---|---|---|

## Migration案
```sql
```

## 注意点
- 既存テーブルへの影響 / 要確認事項 / 将来の拡張で問題になりうる点
```

実例は [examples/](examples/README.md) を参照。
