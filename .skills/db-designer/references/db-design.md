# DB設計リファレンス(Supabase / PostgreSQL)

db-designer スキルの Step 3〜6 で参照する。
既存スキーマの調査コマンドは [system-investigator の supabase.md](../../system-investigator/references/supabase.md) を参照。

## 目次

1. [正規化と「分けるか持たせるか」の判断](#1-正規化と分けるか持たせるかの判断)
2. [カラム設計の定石](#2-カラム設計の定石)
3. [RLS ポリシーのパターン集](#3-rls-ポリシーのパターン集)

---

## 1. 正規化と「分けるか持たせるか」の判断

別テーブルに分ける目安:

- 1対多になる(1ユーザーに複数の住所、など)
- 独立したライフサイクルを持つ(親と無関係に作成・削除される)
- RLSの条件が親と異なる(管理者のみ書ける設定値、など)
- NULLだらけのオプションカラム群になりそう(サブタイプはテーブル分割か jsonb)

同一テーブルに持たせる目安:

- 常に親と一緒に読み書きされる1対1の属性
- 行数が増えない単純な属性

jsonb を使ってよいケース・避けるケース:

- 使ってよい: スキーマが可変な設定値、外部APIのレスポンス保存、検索条件にしない付帯情報
- 避ける: JOIN・集計・RLS条件に使う値、FK で整合性を取りたい値

多対多は必ず中間テーブル(例: `project_members(project_id, user_id, role)`)。
中間テーブルには複合 unique (`project_id, user_id`) を付ける。

## 2. カラム設計の定石

### 型の選定

| 用途 | 推奨型 | 備考 |
|---|---|---|
| PK | `uuid default gen_random_uuid()` | Supabase 標準。連番が必要なら `bigint generated always as identity` |
| 文字列 | `text` | PostgreSQL では varchar(n) より text + check 制約が柔軟 |
| 金額 | `numeric` | float は使わない |
| 日時 | `timestamptz` | `timestamp`(タイムゾーンなし)は使わない |
| 真偽 | `boolean not null default false` | NULL を許すと3値になり事故のもと |
| 区分値 | `text + check` または enum 型 | 値が増える可能性が高いなら check 制約の方が変更が楽 |

### 共通カラム

```sql
created_at timestamptz not null default now(),
updated_at timestamptz not null default now()
```

`updated_at` の自動更新はトリガーで行う(プロジェクトに既存の `set_updated_at()` 関数があれば再利用):

```sql
create trigger set_updated_at before update on <table>
  for each row execute function set_updated_at();
```

### FK と ON DELETE

- `auth.users` を参照する場合: `user_id uuid not null references auth.users(id) on delete cascade`
- 業務データ同士は `on delete restrict`(誤削除防止)を基本にし、cascade は「親が消えたら無意味になる子」だけに使う

### 論理削除の判断

- 必要: 復元要件がある、削除後も履歴・集計に使う、ユーザー操作の取り消しがある
- 不要: 中間テーブル、ログ系、復元要件がないマスタ
- 採用する場合は `deleted_at timestamptz`。**RLSと unique 制約の両方に deleted_at の考慮が必要**
  (unique は `create unique index ... where deleted_at is null` の部分インデックスにする)

### audit log の判断

- 必要: 管理者操作、課金・権限変更、個人情報の変更
- 実装: `audit_logs(id, actor_id, action, target_table, target_id, payload jsonb, created_at)` を1本持ち、
  アプリ側(Server Action / Route Handler)で記録するのが運用しやすい

## 3. RLS ポリシーのパターン集

RLS設計の原則: **テーブル作成と同時に `enable row level security` する。ポリシーは操作別(select / insert / update / delete)に書く。**

### 本人のみ(ユーザー所有データ)

```sql
alter table profiles enable row level security;

create policy "select own" on profiles for select
  using (auth.uid() = user_id);
create policy "update own" on profiles for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

### 全員読み取り・管理者のみ書き込み

```sql
create policy "public read" on announcements for select
  using (published_at <= now());
create policy "admin write" on announcements for all
  using (exists (
    select 1 from user_roles
    where user_id = auth.uid() and role = 'admin'
  ));
```

### マルチテナント(organization 単位)

```sql
create policy "org member read" on projects for select
  using (organization_id in (
    select organization_id from organization_members
    where user_id = auth.uid()
  ));
```

メンバーシップ判定はサブクエリではなく `security definer` 関数にまとめると、
ポリシー間で再利用でき、RLSの再帰(members テーブル自身のRLS)も避けられる:

```sql
create function is_org_member(org_id uuid) returns boolean
language sql security definer set search_path = public as $$
  select exists (
    select 1 from organization_members
    where organization_id = org_id and user_id = auth.uid()
  );
$$;
```

### 注意点

- `using` は読み取り対象の行の条件、`with check` は書き込まれる行の条件。**update には両方**書く
- insert ポリシーは `with check` のみ
- RLS条件で使うカラム(`user_id`, `organization_id`)には必ず index を張る(全行スキャン防止)
- クライアント直アクセスがないテーブルも RLS は有効化し、ポリシーなし(=全拒否)にしておく
