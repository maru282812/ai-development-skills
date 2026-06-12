# examples

migration-review の使用例。実際のレビュー結果は `<migration名>.md` でこのディレクトリに追加する。

## 例1: users テーブルへの plan カラム追加

### 入力例

> この migration、本番適用して大丈夫? 既存データ壊れない?
>
> ```sql
> alter table users add column plan text not null;
> create table billing_logs (
>   id uuid primary key default gen_random_uuid(),
>   user_id uuid references auth.users(id),
>   amount numeric not null,
>   created_at timestamptz default now()
> );
> ```

### Skill が見る観点

- `not null` 追加に default がない → 既存行があると migration 自体が失敗
- `billing_logs` に `enable row level security` がない → anon キーで全件読める
- `billing_logs` の select/insert ポリシーがない(有効化しても全拒否で意図と合うか要確認)
- `user_id` に index がない(FK・RLS条件で使うのに)
- rollback: どちらも追加系なので逆SQLで戻せる

### 出力例(短縮版)

```md
# Migration レビュー: 20260612_add_plan_and_billing_logs.sql

## 判定
**修正必要** — NOT NULL 追加が既存行で失敗する。billing_logs の RLS 有効化漏れは重大。

## 危険箇所
| # | 行/SQL | 問題 | 影響 |
|---|---|---|---|
| 1 | alter table users add column plan text not null | default なし NOT NULL | 既存行があると適用失敗 |
| 2 | create table billing_logs | RLS 未有効化 | 課金情報が anon キーで全件読める |

## RLS確認
| テーブル | RLS有効化 | select | insert | update | delete | 備考 |
|---|---|---|---|---|---|---|
| billing_logs | なし | - | - | - | - | 有効化 + 本人select のみ追加を推奨 |

## 修正SQL案
alter table users add column plan text not null default 'free';
alter table billing_logs enable row level security;
create policy "select own" on billing_logs for select using (auth.uid() = user_id);
create index on billing_logs (user_id);

## 本番適用前チェック
- [ ] ローカルで supabase db reset 確認
- [ ] select count(*) from users; で既存行数を把握
```
