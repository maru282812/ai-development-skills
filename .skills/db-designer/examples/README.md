# examples

db-designer の使用例。実際の設計結果は `<機能名>.md` でこのディレクトリに追加する。

## 例1: タスク管理機能のテーブル設計

### 入力例

> プロジェクトごとにタスクを管理したい。タスクには担当者・ステータス・期限がある。RLS 前提で設計して。Supabase のテーブルを作りたい。

### Skill が見る観点

- 既存の `projects` / `organization_members` テーブルとの関係(マルチテナント分離の単位)
- 担当者は1人か複数か → 複数なら中間テーブル `task_assignees`
- ステータスは enum か check 制約か(将来値が増えるか)
- RLS: プロジェクトメンバーのみ読み書き → 既存の `is_org_member` 系関数を再利用できるか
- 期限・ステータスでの絞り込みが多い → index の検討
- 削除要件 → タスクは復元したい可能性があるため論理削除を提案

### 出力例(短縮版)

```md
# DB設計: タスク管理

## DB設計方針
tasks をプロジェクト配下に置き、RLS はプロジェクトメンバーシップで判定。
担当者は複数想定のため task_assignees に分離。ステータスは check 制約(値追加に強い)。

## テーブル一覧
| テーブル | 責務 | 新規/既存変更 |
|---|---|---|
| tasks | タスク本体 | 新規 |
| task_assignees | タスクと担当者の多対多 | 新規 |

## カラム定義
### tasks
| カラム | 型 | NULL | default | 制約 | 説明 |
|---|---|---|---|---|---|
| id | uuid | NO | gen_random_uuid() | PK | |
| project_id | uuid | NO | | FK projects(id) on delete cascade | |
| title | text | NO | | check (char_length(title) <= 200) | |
| status | text | NO | 'todo' | check (status in ('todo','doing','done')) | |
| due_date | date | YES | | | |
| deleted_at | timestamptz | YES | | | 論理削除 |

## RLS方針
| テーブル | 操作 | 対象者 | 条件 |
|---|---|---|---|
| tasks | select/insert/update | プロジェクトメンバー | is_project_member(project_id) |

## Index / Constraint
| テーブル | 種別 | 対象カラム | 理由 |
|---|---|---|---|
| tasks | index | project_id | FK・RLS条件 |
| tasks | index | (project_id, status) | 一覧の絞り込み |

## Migration案
(create table + RLS + index の SQL)
```
