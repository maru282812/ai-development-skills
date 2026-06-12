# Migration 安全性リファレンス(Supabase / PostgreSQL)

migration-review スキルの Step 3(危険操作のチェック)・Step 6(rollback)で参照する。
RLS ポリシーの書き方は [db-designer の db-design.md](../../db-designer/references/db-design.md) セクション3を参照。

## 目次

1. [危険操作一覧](#1-危険操作一覧)
2. [安全な書き換えパターン](#2-安全な書き換えパターン)
3. [rollback と expand-contract](#3-rollback-と-expand-contract)

---

## 1. 危険操作一覧

| 操作 | 危険度 | 何が起きるか |
|---|---|---|
| `drop table` / `drop column` | 高 | データ消失。rollback 不可。コードが参照していれば即障害 |
| `alter column type` | 高 | 変換不能な既存値があると失敗。テーブル書き換えで長時間ロック |
| 既存テーブルへの `not null` 追加(default なし) | 高 | 既存行に NULL があると失敗。なくても将来の insert 失敗リスク |
| `add constraint check/unique`(既存データ違反あり) | 高 | migration 自体が失敗。事前に違反データの有無を確認する |
| カラム/テーブルの rename | 高 | 旧名を参照するコードが即死。expand-contract 必須 |
| `truncate` / `delete` / `update`(データ操作) | 高 | rollback 不可。バックアップ前提でしか実行しない |
| enum 値の削除・rename | 高 | PostgreSQL では値の削除不可(型作り直し)。追加は可 |
| `create index`(同期) | 中 | 大テーブルで書き込みロック。`concurrently` は transaction 外でのみ可 |
| `not null` + `default` 追加 | 低〜中 | PG11+ は高速だが、volatile な default(`now()` 等)は全行書き換え |
| `create table` + RLS 有効化漏れ | 高(security) | エラーは出ないが anon キーで全行読める状態になる |

確認用クエリの例(適用前にローカル/ステージングで実行):

```sql
-- NOT NULL 追加前: NULL の既存行がないか
select count(*) from <table> where <column> is null;
-- check 制約追加前: 違反する既存行がないか
select count(*) from <table> where not (<制約条件>);
-- unique 制約追加前: 重複がないか
select <column>, count(*) from <table> group by <column> having count(*) > 1;
```

## 2. 安全な書き換えパターン

### NOT NULL カラムの追加

```sql
-- NG: 既存行があると失敗
alter table users add column plan text not null;

-- OK: default 付きで追加(既存行は default で埋まる)
alter table users add column plan text not null default 'free';
```

default を持たせたくない場合は3段階に分ける:
1. NULL 許可で追加 → 2. 既存行を UPDATE で埋める → 3. `set not null`

### 制約の追加(大テーブル)

```sql
-- 検証を後回しにしてロックを短くする
alter table orders add constraint amount_positive
  check (amount > 0) not valid;
alter table orders validate constraint amount_positive;
```

### enum 値の追加

```sql
alter type task_status add value 'archived';
```

※ enum への値追加は transaction 内で使えない場合がある(古いPG)。check 制約方式なら通常の ALTER で済む。

## 3. rollback と expand-contract

### rollback 可否の分類

- **戻せる**: create table / add column(削除すればよい)、create index、policy 追加
- **条件付きで戻せる**: 制約追加(drop constraint)、default 変更
- **戻せない**: drop / truncate / update・delete によるデータ変更、型変更で精度が落ちたもの
  → 戻せない操作は適用前バックアップ(`pg_dump` または Supabase のバックアップ)を必須とする

### expand-contract(コードと同時に変えない)

カラム rename・型変更・テーブル分割は以下の3デプロイに分ける:

```text
1. expand   : 新カラム/新テーブルを追加。旧と並存(両書きまたはトリガー同期)
2. migrate  : コードを新側参照に切り替え。データをバックフィル
3. contract : 旧カラム/旧テーブルを削除(十分な安定期間の後)
```

### 本番適用順序の原則

- **追加系 migration → コードデプロイ**(新コードが新カラムを前提とするため先にDB)
- **コードデプロイ → 削除系 migration**(旧コードが参照しなくなってからDB)
- 1つの migration に追加と削除が混在していたら、この原則に従って分割を提案する
