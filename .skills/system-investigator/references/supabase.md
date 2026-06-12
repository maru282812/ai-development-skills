# Supabase 調査リファレンス

system-investigator スキルの Step 3(DB確認)・Step 5(Supabaseクライアント呼び出し確認)で参照する。

## 目次

1. [migrationファイルの場所と命名規則](#1-migrationファイルの場所と命名規則)
2. [RLSポリシーの確認方法](#2-rlsポリシーの確認方法)
3. [テーブル/カラムからコード内使用箇所を特定する方法](#3-テーブルカラムからコード内使用箇所を特定する方法)
4. [Edge Functions / Database Functions / Triggers](#4-edge-functions--database-functions--triggers)

---

## 1. migrationファイルの場所と命名規則

- 標準の場所: `supabase/migrations/`
- 命名規則: `<timestamp>_<説明>.sql`(例: `20240115103000_create_users_table.sql`)
- timestampの昇順に適用されるため、**同名テーブルへの変更が複数ファイルに分散している**ことに注意。最新の定義を知るには対象テーブルに触れる全migrationを時系列で追うこと

```bash
# migrationファイル一覧(適用順)
ls supabase/migrations/
# 対象テーブルに触れる全migrationを特定
rg -i 'table_name' supabase/migrations/ -l
# テーブル定義(CREATE文)を探す
rg -i 'create table.*table_name' supabase/migrations/
# カラム追加・変更の履歴
rg -i 'alter table.*table_name' supabase/migrations/
```

補足:
- `supabase/seed.sql` に初期データがある場合がある
- migrationを使わずダッシュボードで直接変更しているプロジェクトでは、`supabase db pull` で取得したスキーマや `database.types.ts`(型生成ファイル)が実態に近い。**migrationと型定義ファイルが食い違う場合は要確認事項として報告する**
- 型生成ファイルの場所: `rg --files -g '*database.types.ts' -g '*supabase.types.ts'` で特定。テーブル・カラムの現在の構造を確認する一次情報として有用

## 2. RLSポリシーの確認方法

RLSポリシーはmigration内のSQLとして定義されているのが基本。

```bash
# RLS有効化の確認
rg -i 'enable row level security' supabase/migrations/
# 対象テーブルのポリシー定義を探す
rg -i 'create policy' supabase/migrations/
rg -i 'policy.*on.*table_name' supabase/migrations/
# ポリシー内で使われる関数(auth.uid()等)も確認
rg -i 'auth\.uid\(\)|auth\.jwt\(\)' supabase/migrations/
```

確認すべきポイント:
- 対象テーブルでRLSが**有効か無効か**(無効なら全行アクセス可能 — それ自体を注意点として報告)
- 操作別(SELECT / INSERT / UPDATE / DELETE)のポリシーの有無と条件
- ポリシーが参照する他テーブル・関数(変更時の影響範囲に含める)
- `service_role` キー経由のアクセスはRLSをバイパスする(nextjs.md の管理者クライアントの項を参照)

ローカル環境が動いている場合はSQLで直接確認もできる:
```sql
select * from pg_policies where tablename = 'table_name';
```

## 3. テーブル/カラムからコード内使用箇所を特定する方法

### .from() 呼び出しの検索

```bash
# テーブルへの全アクセス箇所
rg "\.from\(['\"]table_name['\"]\)" --glob '*.ts' --glob '*.tsx'
# 操作別に絞る(複数行にまたがるためコンテキスト付きで)
rg "\.from\(['\"]table_name['\"]\)" -A 3 --glob '*.ts' --glob '*.tsx'
```

ヒットした各箇所について以下を記録する:
- 操作種別: `.select()` / `.insert()` / `.update()` / `.upsert()` / `.delete()`
- 実行コンテキスト: Client Component(`'use client'`)か、Server側(Server Component / Route Handler / Server Action)か
- 対象カラム: `.select('col1, col2')` の引数、`.eq('column', ...)` などのフィルタ条件

### RPC(Database Function)呼び出しの検索

```bash
# RPC呼び出し箇所
rg "\.rpc\(" --glob '*.ts' --glob '*.tsx'
rg "\.rpc\(['\"]function_name['\"]" --glob '*.ts' --glob '*.tsx'
```

### カラム名での検索

- カラム名はコード上では `.eq('column_name', ...)`、select文字列、型定義(`database.types.ts`)、フォームのname属性などに現れる
- 汎用的な名前(`name`, `status` 等)は誤ヒットが多いため、テーブル名とセットで確認する

### その他のアクセス経路

```bash
# 生SQLの実行(まれだが存在しうる)
rg -i 'table_name' --glob '*.sql' --glob '*.ts' -l
# Realtimeサブスクリプション(変更通知を購読している画面)
rg "\.channel\(|postgres_changes" --glob '*.ts' --glob '*.tsx'
# Storage(テーブルではなくバケットの場合)
rg "\.storage\.from\(" --glob '*.ts'
```

## 4. Edge Functions / Database Functions / Triggers

### Edge Functions

- 場所: `supabase/functions/<function-name>/index.ts`
- Deno環境で動くため、import形式が通常のNext.jsコードと異なる(URLインポート)

```bash
# Edge Functions の一覧
ls supabase/functions/
# 対象テーブルを操作しているEdge Functionを探す
rg 'table_name' supabase/functions/
# Edge Functionの呼び出し元(Next.js側)
rg "functions\.invoke\(" --glob '*.ts' --glob '*.tsx'
```

- cron実行されている場合がある: `supabase/config.toml` の `[functions.<name>]` や、migration内の `cron.schedule(...)` (`pg_cron`)を確認する

### Database Functions

- migration内に `create function` / `create or replace function` として定義される

```bash
rg -i 'create (or replace )?function' supabase/migrations/
```

確認ポイント:
- 関数本体で対象テーブル・カラムを参照していないか(カラム名で関数本体を検索)
- `security definer` 指定の関数はRLSをバイパスして動く — 影響範囲分析で重要
- コード側からの呼び出しは `.rpc('function_name')` で検索(セクション3参照)

### Triggers

- migration内に `create trigger` として定義される

```bash
rg -i 'create trigger' supabase/migrations/
rg -i 'trigger.*on.*table_name' supabase/migrations/
```

確認ポイント:
- 対象テーブルへのINSERT/UPDATE/DELETE時に副作用(他テーブルの更新、`updated_at` の自動設定、監査ログ等)が発生しないか
- トリガーが呼ぶ関数の本体も追跡する(Database Functionsの項と同様)
- `auth.users` へのトリガー(サインアップ時のプロフィール自動作成など)は見落としやすいので注意

### Database Webhooks / 外部連携

```bash
# Database Webhooks(supabase_functionsスキーマ経由)
rg -i 'supabase_functions|http_request' supabase/migrations/
# pg_net による外部API呼び出し
rg -i 'pg_net|net\.http' supabase/migrations/
```
